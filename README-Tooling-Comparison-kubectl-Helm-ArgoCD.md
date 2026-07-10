# 1. Tooling Comparison: kubectl, Helm, ArgoCD
## 1.1. What Each Tool Is Responsible For

| Dimension         | kubectl                                | Helm                                     | ArgoCD                                |
|-------------------|----------------------------------------|------------------------------------------|---------------------------------------|
| Primary purpose   | Imperative cluster interaction         | Declarative package + release management | Continuous declarative      
                                                                                                        | reconciliation|       
| State model       | Stateless (no memory of what it did)   | Stateful (release history as Secrets)    | Stateful (Application CR + sync 
                                                                                                        |            history)    
| Templating        | None                                   | Yes — Go templates + values              | Delegates to Helm, Kustomize,          
                                                                                                        |    or plain YAML                       
| Drift detection   | None                                   | None                                     | Core feature                           
| Rollback          | kubectl rollout undo (Deployment only) | helm rollback N (full release)           | argocd app rollback N (Git commit)     
| Audit trail       | Kubernetes events + audit log          | Helm release Secrets                     | ArgoCD sync history + Git history      
| Access model      | Direct cluster credentials             | Direct cluster credentials               | ArgoCD has credentials-CI/humans do not
| Multi-environment | Manual namespace targeting             | Manual -f values-env.yaml                | Declarative per Application            
| GitOps compliance | No                                     | No                                       | Yes — Git is source of truth           

## 1.2. How They Work Together
### 1.2.1. Development workflow:
```console
  kubectl → direct interaction for debugging, not for deployments
  kubectl exec, kubectl logs, kubectl describe → diagnostic tooling
  kubectl auth can-i → RBAC verification
```

### 1.2.2. Release packaging:
```console
  helm lint → chart validation in CI
  helm template → manifest preview
  helm unittest → chart unit tests
  helm package → publish to OCI registry
  (Note: helm upgrade is NOT used in GitOps — ArgoCD runs it)
```
  
### 1.2.3. Continuous delivery:
```console
  argocd app sync → manual promotion trigger
  argocd app diff → pre-sync change preview
  argocd app rollback → emergency recovery
  argocd app get → status check in CI
```
## 1.3. Avoiding Confusion When All Three Touch the Same Application
### 1.3.1. The most dangerous pattern is mixed ownership — where kubectl, Helm, and ArgoCD all modify the same resource:

#### 1.3.1.1. WRONG (production incident recipe):
```console
  1. ArgoCD manages Deployment (via Helm chart in Git)
  2. Developer runs: kubectl set image deployment/myapp myapp=v2.0
  3. ArgoCD detects drift → selfHeal reverts to Git version
  4. Developer confused: "my change keeps disappearing"
  
  OR:
  5. Developer runs: helm upgrade myapp ./charts/myapp --set replicas=5
  6. ArgoCD detects diff → reverts to replicas=2 from Git values
  7. Developer confused: "helm upgrade succeeded but nothing changed"
```
#### 1.3.1.2. CORRECT:
```console
  Single authority: ArgoCD is the only actor that applies to the cluster
  kubectl: read-only in production (kubectl get, describe, logs, exec)
  Helm: packaging only (helm template, helm lint, helm package)
  ArgoCD: the only writer (argocd app sync, automated sync)
```
### 1.3.2. Enforcement mechanism: 
#### 1.3.2.1. RBAC:  
   1. Production namespace myapp-prod should have a RoleBinding that gives developers only get/list/watch verbs. 
   2. Only the ArgoCD ServiceAccount has create/update/patch/delete verbs.