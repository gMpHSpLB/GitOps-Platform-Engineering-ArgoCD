# 1. Project: 
### 1.0.1. "GitOps Platform Engineering: Operating a Production ArgoCD Instance with Application Lifecycle Management, Drift Detection, and Sync Strategy Control"

## 1.1. What GitOps Means
GitOps is an operational model where the desired state of every system is declared in Git, and an automated agent continuously ensures the actual state converges to the desired state. It is not a tool — it is a set of principles. ArgoCD is an implementation of those principles for Kubernetes.
The four GitOps principles (OpenGitOps 1.0.0):
1.	Declarative: The entire system is described declaratively
2.	Versioned and immutable: Desired state is stored in a way that enforces immutability and versioning
3.	Pulled automatically: Software agents automatically pull the desired state declarations
4.	Continuously reconciled: Software agents continuously observe actual system state and attempt to apply the desired state

### 1.1.1. Desired State vs Actual State

```console
+---------------+-------------------------+-------------------------+------------------------+
| Term          | Where it lives          | Who writes it           | Who reads it           |
+---------------+-------------------------+-------------------------+------------------------+
| Desired state | Git repository          | Developer / ops         | ArgoCD repo-server     |
|               |                         | engineer                |                        |
+---------------+-------------------------+-------------------------+------------------------+
| Actual state  | Kubernetes API server   | Kubernetes controllers  | ArgoCD app-controller  |
|               | (etcd)                  |                         |                        |
+---------------+-------------------------+-------------------------+------------------------+
```
The gap between desired and actual is called drift. GitOps eliminates drift by making convergence continuous and automatic.

## 1.2. Pull-Based Deployment Model
### 1.2.1. Traditional CD (push model): 
CI pipeline has cluster credentials and runs kubectl apply. The cluster is a passive recipient.
### 1.2.2. GitOps CD (pull model): 
ArgoCD runs inside the cluster and pulls from Git. CI has no cluster credentials. The cluster is an active participant in its own configuration.
### 1.2.3. Why pull-based is more secure:
```console
•	CI system compromise does not give an attacker cluster access
•	Cluster access is controlled by ArgoCD's own RBAC, not distributed across every CI runner
•	Blast radius of a CI breach is limited to the Git repository, not the production cluster
```
## 1.3. Drift Detection
ArgoCD detects drift through two mechanisms:
```console
1. Watch events (near real-time): ArgoCD subscribes to Kubernetes watch events for all namespaces it manages. When any managed resource is modified (by a human or another controller), the watch event triggers immediate re-comparison. Response time: seconds.

2. Periodic reconciliation (fallback): Every timeout.reconciliation (default 180s), ArgoCD re-fetches all managed resources and compares against the rendered desired state. This catches drift that watch events missed (e.g., a change made while ArgoCD was restarting).
```
## 1.4. Self-Healing
```console
1. When selfHeal: true, drift triggers an automatic sync. ArgoCD applies the desired state from Git, overwriting the manual change. This is the enforcement mechanism of the GitOps contract: Git wins, always.

2. When selfHeal: false (appropriate for staging/prod), drift is detected and reported (OutOfSync status, notification sent) but not automatically corrected. A human must review and sync manually.
```

## 1.5. Multi-Environment Promotion
Git branch: main
  │
  ├── envs/dev/values.yaml        → Application: myapp-dev  (auto-sync)
  ├── envs/staging/values.yaml    → Application: myapp-staging (manual sync)
  └── envs/prod/values.yaml       → Application: myapp-prod   (manual sync + AppProject RBAC)

### 1.5.1. Promotion workflow:
```console
  1. CI commits image.tag update to envs/dev/values.yaml
  2. ArgoCD auto-deploys to dev
  3. QA validates dev
  4. Engineer creates PR: envs/dev/values.yaml → envs/staging/values.yaml
  5. PR approved → merged
  6. ArgoCD detects staging Application is OutOfSync
  7. Engineer reviews ArgoCD diff, clicks Sync (or argocd app sync myapp-staging)
  8. Repeat for prod with change window controls
```
## 1.6. Auditability and Compliance
Every change to the cluster in a GitOps model has:
```console
•	A Git commit SHA (immutable reference)
•	An author (Git user identity)
•	A commit message (change description)
•	A timestamp (Git commit time)
•	A code review trail (PR approvals)
```
This satisfies SOC2, ISO27001, and PCI-DSS audit requirements for change management. 
Traditional kubectl apply from CI systems have none of this by default.

## 1.7. Rollback Strategy
```console
+-------------------+-------------------------+----------------+----------------------------+
| Rollback type     | Mechanism               | Speed          | Auditability               |
+-------------------+-------------------------+----------------+----------------------------+
| Git revert        | git revert <sha>        | Slow           | Perfect — creates audit    |
|                   | + merge                 | (PR required)  | record                    |
+-------------------+-------------------------+----------------+----------------------------+
| ArgoCD rollback   | argocd app rollback     | Fast           | Partial — logged in ArgoCD,|
|                   | <name> <rev>            | (seconds)      | not Git                   |
+-------------------+-------------------------+----------------+----------------------------+
| Helm rollback     | helm rollback <release> | Fast           | Release Secret only       |
| (fallback)        | N                       | (seconds)      |                            |
+-------------------+-------------------------+----------------+----------------------------+
```
### 1.7.1. Enterprise rule:
```console
   - Git revert is the preferred rollback method for planned changes. 
   - ArgoCD rollback is for emergency recovery. After an emergency rollback, a Git revert must follow to bring the repository back in sync with the cluster — otherwise, the next sync will re-apply the bad version.
```
