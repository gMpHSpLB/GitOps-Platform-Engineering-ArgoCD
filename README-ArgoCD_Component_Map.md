# 1. ArgoCD Internal Architecture - Component Map

```console
                External traffic (UI, CLI, CI)
                        │
                        ▼
                argocd-server (Deployment)
                ├── Serves Web UI (React SPA)
                ├── Serves gRPC API (argocd CLI)
                ├── Serves REST API (CI systems)
                ├── Handles auth (local + OIDC via dex)
                ├── Executes sync operations (kubectl apply)
                └── Manages RBAC enforcement
                        │
                        │ render requests
                        ▼
                argocd-repo-server (Deployment)
                ├── Clones Git repositories
                ├── Runs: helm template / kustomize build / plain YAML
                ├── Returns rendered YAML to application-controller
                ├── Caches rendered manifests in Redis
                └── ISOLATED — no Kubernetes API access
                        │
                        │ cached manifests
                        ▼
                argocd-redis (Deployment)
                ├── Caches rendered manifests (avoids re-rendering on every reconciliation)
                ├── Caches live cluster state (avoids re-fetching on every diff)
                ├── Stores session data for argocd-server
                └── Ephemeral — no persistence (cache rebuilt on restart)
                        │
                argocd-application-controller (StatefulSet, 0)
                ├── The reconciliation engine
                ├── Watches Application CRs in argocd namespace
                ├── Watches all managed resources in target namespaces
                ├── Requests renders from repo-server
                ├── Fetches live state from Kubernetes API
                ├── Computes sync status and health status
                ├── Triggers syncs (if automated)
                └── Updates Application.status
                        │
       Optional supporting components
      --------------------------------                 
                argocd-dex-server (Deployment)
                ├── OIDC connector for SSO
                ├── Translates OIDC tokens to ArgoCD user identity
                └── Required only when using SSO (Okta, GitHub, Google)

                argocd-notifications-controller (Deployment)
                ├── Sends alerts to Slack, PagerDuty, email, webhook
                ├── Triggered by Application sync events, health changes
                └── Configured via ConfigMap and Secret

                argocd-applicationset-controller (Deployment)
                ├── Manages ApplicationSet CRs
                ├── Runs generators (List, Cluster, Git, Matrix, PR)
                └── Creates/updates/deletes Application CRs based on generator output
```
## 1.1. Simple flow explanation
Step 1: Users and systems talk to argocd-server.
Step 2: argocd-server authenticates the request and applies RBAC rules.
Step 3: When manifests must be rendered, argocd-server or the controller asks argocd-repo-server.
Step 4: argocd-repo-server pulls Git and renders Helm, Kustomize, or plain YAML.
Step 5: argocd-redis helps cache render and state data so Argo CD does not recompute everything every time.
Step 6: argocd-application-controller compares desired state with live cluster state and performs reconciliation.
Step 7: Optional components like dex, notifications, and ApplicationSet extend identity, alerting, and fleet management.

## 1.2. Shorter mental model
```console
    -> argocd-server = front door
    -> argocd-repo-server = manifest renderer
    -> argocd-redis = cache
    -> argocd-application-controller = brain
    -> argocd-dex-server = SSO bridge
    -> argocd-notifications-controller = alerting
    -> argocd-applicationset-controller = Application factory
```

| Component                        | Responsibility                                 | Failure Impact  
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-server                    | UI, API, auth, RBAC, sync requests             | Users cannot access UI/API; CLI and CI 
                                                                                        requests fail
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-repo-server               | Clone Git and render Helm/Kustomize/YAML       | Manifests cannot be rendered; syncs and 
                                                                                        diffs fail
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-redis                     | Cache rendered manifests, live state, sessions | Slower reconciliations; cache rebuild 
                                                                                        needed after restart
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-application-controller    | Reconciliation, diff, health, auto-sync        | Argo CD cannot detect drift or sync 
                                                                                        applications 
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-dex-server                | SSO / OIDC authentication bridge               | SSO login fails; local auth may still     
                                                                                        work
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-notifications-controller  | Alerts to Slack, email, webhooks               | Sync/health notifications 
                                                                                        stop 
| -------------------------------- | ---------------------------------------------- |--------------------------------------- |
| argocd-applicationset-controller | Generate and manage Applications               | ApplicationSet automation stops; app 
                                                                                        fleet may go stale   


| Component fails                  | Immediate impact                                         | Long-term impact                                                       |
|----------------------------------|----------------------------------------------------------|------------------------------------------------------------------------|
| argocd-server                    | UI inaccessible, CLI fails, no manual syncs              | Auto-sync continues (application-controller works independently)       |
| argocd-repo-server               | No manifest rendering → no new syncs possible            | Drift accumulates undetected, new deployments blocked                  |
| argocd-application-controller    | No reconciliation, no drift detection, no health updates | Cluster drifts silently — most critical component                      |
| argocd-redis                     | Cache miss → repo-server re-renders everything           | Performance degradation, higher Git clone rate, higher API server load |
| argocd-dex-server                | SSO login fails — only local admin account works         | Operators locked out (if no local account configured)                  |
| argocd-applicationset-controller | No new ApplicationSets processed                         | Existing Applications continue, new ones not created                   |
| argocd-notifications-controller  | No Slack/PagerDuty alerts on sync events                 | Silent failures — operators not notified                               |
### 1.2.1. Failure Impact Analysis
| Component fails                 | Immediate impact       | Long-term impact           |
|---------------------------------|------------------------|----------------------------|
|argocd-server                    | UI inaccessible,       |Auto-sync                   |
|                                 |CLI fails,              |continues                   |
|                                 |no manual syncs         |(application-controller     |
|                                 |                        |works independently)        |
|---------------------------------|------------------------|----------------------------|
|argocd-repo-server               |No manifest             |Drift accumulates           |
|                                 |rendering → no new      |undetected, new             |
|                                 |syncs possible          |deployments blocked         |
|---------------------------------|------------------------|----------------------------|
|argocd-application-controller    |No reconciliation,      |Cluster drifts              |
|                                 |no drift detection,     |silently — most             |
|                                 |no health updates       |critical component          |
|---------------------------------|------------------------|----------------------------|
|argocd-redis                     |Cache miss → repo-server|Performance degradation,    |
|                                 |re-renders everything   |higher Git clone            |
|                                 |                        |rate, higher API            |
|                                 |                        |server                      |
|---------------------------------|------------------------|----------------------------|
|argocd-dex-server                |SSO login fails         |Operators locked            |
|                                 |only local-             |out (if no local account-   |
|                                 |admin account works     |configured)                 |
|---------------------------------|------------------------|----------------------------|
|argocd-applicationset-controller |No new                  |Existing Applications       |
|                                 |ApplicationSets         |continue, new               |
|                                 |processed               |ones not created            |
|---------------------------------|------------------------|----------------------------|
|argocd-notifications-controller  |No Slack/PagerDuty      |Silent failures —           |
|                                 |alerts on sync events   |operators not notified      |
|---------------------------------|------------------------|----------------------------|

## 1.3. HA configuration for production:
```console
    # application-controller: StatefulSet (already single-shard by default)
    # Scale with sharding for large fleets (>100 Applications):
    argocd-application-controller:
    env:
        - name: ARGOCD_CONTROLLER_REPLICAS
        value: "3"   # 3-shard mode

    # repo-server: scale horizontally for many concurrent renders
    argocd-repo-server:
    replicas: 3

    # argocd-server: stateless, scale freely
    argocd-server:
    replicas: 3

    # redis: use Redis Sentinel or Redis Cluster for HA
    # (ArgoCD supports Redis HA via argocd-redis-ha chart)
```

