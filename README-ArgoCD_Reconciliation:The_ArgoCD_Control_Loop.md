# 1. Reconciliation: The ArgoCD Control Loop
## 1.1. What Triggers Reconciliation
ArgoCD uses two complementary mechanisms:
1. Mechanism 1: Kubernetes watch events (near real-time)
2. Mechanism 2: Periodic reconciliation (fallback)

### 1.1.1. Mechanism 1: Kubernetes watch events (near real-time)
ArgoCD's application-controller subscribes to Kubernetes watch events for all managed namespaces. When any managed resource is modified (annotation added, label changed, image updated by another actor), the API server sends a watch event. The application-controller receives it within seconds and re-queues the Application for comparison.

```console
        kubectl edit deployment myapp -n myapp-dev
                │
                ▼ (milliseconds)
        API server sends watch event to all connected watchers
                │
                ▼ (< 1 second)
        ArgoCD application-controller receives event
                │
                ▼ (2-5 seconds)
        Application re-queued for comparison
                │
                ▼ (5-30 seconds, depending on repo-server cache)
        Desired state rendered from Git
                │
                ▼
        Comparison: edited value ≠ Git value → OutOfSync
                │
                ▼ (if selfHeal: true)
        argocd-server executes kubectl apply → drift corrected
                │
                ▼ (10-30 seconds total from edit to revert)
        Application → Synced + Healthy
```
### 1.1.2. Mechanism 2: Periodic reconciliation (fallback)
Every timeout.reconciliation seconds (default 180s), all Applications 
are re-queued regardless of watch events. 
This catches:
  -> Watch event missed during ArgoCD restart
  -> Drift caused by a controller that doesn't generate watch events
  -> Git changes that arrived during a network partition

### 1.1.3. Mechanism 3: Webhook-triggered refresh (fastest for Git changes)
Configure a webhook in GitHub/GitLab pointing to https://argocd-server/api/webhook. When a push event arrives, ArgoCD immediately triggers a Git refresh and re-render without waiting for the 180s poll. This reduces deploy-to-sync latency from ~3 minutes to ~10 seconds.

```console
  # Configure webhook URL in GitHub:
  # Settings → Webhooks → Add webhook
  # URL: https://argocd.example.com/api/webhook
  # Content type: application/json
  # Secret: from argocd-secret (webhook.github.secret key)
  # Events: Push events
```
## 1.2. Drift Detection Internals
ArgoCD compares desired state vs actual state using a three-way diff:

```console
Desired state:  What helm template renders from Git
Live state:     What kubectl get <resource> returns from cluster API
Last applied:   The argocd.argoproj.io/app-name annotation + server-side apply field ownership

Diff algorithm:
1. Normalize both sides (remove runtime-injected fields like resourceVersion, status)
2. Apply ignoreDifferences rules (remove explicitly excluded fields)
3. Structural diff: field-by-field comparison
4. If any field differs → OutOfSync
```

## 1.3. Common sources of false-positive drift:
A false-positive drift is when that comparison reports OutOfSync, even though the application is still behaving correctly. This usually happens because Kubernetes is dynamic: other controllers may mutate objects after apply, defaults may get added automatically, or some fields may intentionally be managed outside Git.
### 1.3.1. Practical rule
```console
Use this rule of thumb:
   - Git owns desired intent.
   - Controllers own runtime behavior.
   - Argo CD should compare only the fields that actually belong to Git
```
```console
|---------------------|-----------------------|-----------------------|---------------------|
|Cause of             |What happens           |Why Argo               |Typical              |
|false-positive       |                       |CD flags it            |Fix                  |
|drift                |                       |                       |                     |
|---------------------|-----------------------|-----------------------|---------------------|
|HPA managing         |HPA changes            |Git replica count      |Stop managing        |
|replicas             |`spec.replicas`        |differs from live      |`replicas` in Git    |
|                     |based on load.         |replica count.         |when HPA is enabled. |
|---------------------|-----------------------|-----------------------|---------------------|
|Kubernetes           |API server adds        |Live state has         |Declare defaults     |
|defaulting           |defaulted fields not   |extra values vs        |explicitly in        |
|                     |in Git.                |desired state.         |chart/manifests.     |
|---------------------|-----------------------|-----------------------|---------------------|
|cert-manager         |TLS Secret data        |Secret contents        |Ignore specific      |
|TLS renewal          |changes on             |differ from what       |TLS Secret fields    |
|                     |certificate rotation.  |Git defines.           |in drift rules.      |
|---------------------|-----------------------|-----------------------|---------------------|
|Kubernetes           |API server adds        |Live state has         |Declare defaults     |
|defaulting           |defaulted fields not   |extra values vs        |explicitly in        |
|                     |in Git.                |desired state.         |chart/manifests.     |
|---------------------|-----------------------|-----------------------|---------------------|
|Mutating webhook     |Webhooks add labels,   |Live object has        |Ignore only          |
|injection            |annotations,sidecars,  |injected fields        |injected fields, not |
|                     |tolerations.           |missing in Git.        |the whole resource.  |
|---------------------|-----------------------|-----------------------|---------------------|
|Server-side          |Multiple actors manage |Field ownership        |Use consistent       |
|apply ownership      |different fields       |differences appear     |apply strategy and   |
|                     |of one resource.       |as spec drift.         |clear field ownership.|
|---------------------|-----------------------|-----------------------|----------------------|
```

## 1.4. Self-Healing vs Kubernetes Self-Healing
|```console
 Aspect                | Kubernetes self-healing           | ArgoCD Self-healing                    |
|-----------------------|-----------------------------------|----------------------------------------|
| What it heals         | Runtime failures                  | Configuration drift                    |
                          (pod crashes, node failures)        (human changes, webhook mutations)
|-----------------------|-----------------------------------|----------------------------------------|
| Trigger               | Pod exits, node NotReady,         | Watch event or periodic reconciliation |
                          readiness probe fails               detects diff  
|-----------------------|-----------------------------------|----------------------------------------|
| Authority             | Built-in controllers              | argocd-server calling                  |
                          (ReplicaSet, Deployment)             kubectl apply
|-----------------------|-----------------------------------|----------------------------------------|
| Speed                 | Seconds (kubelet detects          | Seconds to minutes (watch              |
                            immediately)                            event + render + apply)
|-----------------------|-----------------------------------|----------------------------------------|
| What it does NOT heal | Configuration drift               | Runtime failures                       |
|-----------------------|-----------------------------------|----------------------------------------|
| Can they conflict?    | Yes — Deployment rolling          | Avoid by ensuring ArgoCD owns          |
                          update + ArgoCD sync can race       image tag in Git
|-----------------------|-----------------------------------|----------------------------------------|

```

                     

  