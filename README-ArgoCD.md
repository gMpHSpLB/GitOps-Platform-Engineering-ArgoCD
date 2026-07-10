# 1. Operating a Production ArgoCD Instance with Application Lifecycle Management

## 1.1. The ArgoCD architecture 
```console
argocd-server                   → UI and API server. Handles user/CI requests.
argocd-repo-server              → Clones Git repos, renders Helm/Kustomize manifests.
                                  Runs in isolation — no cluster access.
argocd-application-controller   → The heart of ArgoCD. Watches Applications in 
                                  etcd. Compares desired (Git) vs actual (cluster).
                                  Triggers syncs.
argocd-dex-server               → OIDC provider for SSO integration.
```
### 1.1.1. ArgoCD architecture diagram
<img width="2760" height="3440" alt="t03_argocd_architecture" src="https://github.com/user-attachments/assets/4351799a-9d9e-46ac-9761-343090dc88c2" />

## 1.2. How Resources Connect in Practice: In a Helm + ArgoCD workflow
```console
Developer writes code
  → CI builds image (sha256:abc) → pushed to registry
  → CI commits "feat: bump image to sha256:abc" to GitOps repo
  → CI has NO cluster access — its job is done
  
  ArgoCD repo-server detects new commit (watch event or 180s poll)
  → Clones GitOps repo at new HEAD
  → Runs: helm template myapp ./charts/myapp -f values-prod.yaml
  → Sends rendered YAML to app-controller
  → app-controller diffs rendered (desired) vs live cluster state (actual)
  → Diff found: image tag changed
  → If automated → ArgoCD calls argocd-server → kubectl apply patch
  → Kubernetes rolls out new pods with sha256:abc
  → app-controller re-fetches live state → Synced + Healthy
  → Notification sent to Slack
```
## 1.3. The sync loop — what actually happens every 3 minutes (default):
```console
1. argocd-application-controller reads Application object from etcd 
   (etcd is a distributed, strongly consistent key-value store used 
   to store critical cluster data, especially in Kubernetes. It acts 
   as Kubernetes’ backing store for cluster state, configuration, and 
   metadata.)
2. Sends render request to argocd-repo-server:
   "Clone this Git URL at this revision, run helm template with these values"
3. argocd-repo-server renders manifests, returns rendered YAML
4. Controller fetches live state from cluster API for all resources in that namespace
5. Controller diffs rendered YAML (desired) vs live state (actual)
6. If diff exists → Application status = OutOfSync
7. If sync policy = automated → Controller calls argocd-server to apply
8. argocd-server calls kubectl apply on the diff
9. Cluster reconciles
10. Controller re-fetches live state → if matches desired → Synced
```
## 1.4. ArgoCD-Based GitOps Workflow Diagram
<img width="2760" height="3760" alt="argocd_gitops_workflow" src="https://github.com/user-attachments/assets/98f524f6-21dd-4e16-a98c-aba21d2c2fe1" />

## 1.5. What ArgoCD does NOT do:
```console
•	It does not replace Helm. It calls Helm's template engine to render manifests.
•	It does not store application state. The Git repo is the state.
•	It does not automatically redeploy on image changes (that's an image updater or CI push).
•	It does not encrypt secrets. That is External Secrets Operator's job.
```
## 1.6. The GitOps contract ArgoCD enforces:
```console
•	Git is the only source of truth
•	Any manual kubectl apply or kubectl edit to a managed resource is overwritten on next sync
•	Deletion from Git means ArgoCD can prune (delete) the resource from the cluster — if pruning is enabled
```
