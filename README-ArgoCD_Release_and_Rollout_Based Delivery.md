# 1. Release and Rollout in ArgoCD-Based Delivery
## 1.1. The Release Lifecycle
In a Helm-only world, a release is a Helm concept — a named, versioned set of rendered manifests stored as a cluster Secret. Rollback means re-applying a previous Helm release Secret.

### 1.1.1. In an ArgoCD + Helm world, there are two overlapping versioning systems:

```console
Git commit SHA (immutable, permanent, the authoritative source)
     │
     └── ArgoCD sync revision (which Git commit this Application is synced to)
          │
          └── Helm release revision (which helm upgrade execution rendered the manifests)
               │
               └── Deployment rollout revision (which ReplicaSet the Deployment currently uses)
```

## 1.2. Which rollback mechanism to use when:
| Scenario                         | Rollback mechanism                      | Speed    | Audit trail           |
|----------------------------------|---------------------------------------- |----------|-----------------------|
| Bad config in Git merged to main | git revert → PR → merge → ArgoCD syncs  | 5-15 min | Perfect — Git history |

| Bad image tag deployed, need     | argocd app rollback myapp-dev <revision>| 30 sec   | ArgoCD history only   |
    immediate recovery 

| Helm chart bug (not config)	     | Fix chart → push → ArgoCD syncs	       | 2-5 min	| Git history           |

| Database migration went wrong    | Application-level rollback              | Varies   | DB migration log      |
                                      (Flyway/Liquibase) 

| Emergency: ArgoCD unavailable    | helm rollback <release> <N> -n <ns>     | 30 sec   | Helm release Secret   |
|----------------------------------|-----------------------------------------|----------|-----------------------|

### 1.2.1. Critical operational rule: 
After any argocd app rollback, the Git repository is out of sync with the 
cluster. The next ArgoCD sync will re-apply the bad version. You must 
immediately either:
    1. Create a Git revert commit to bring Git back in line with the cluster
    2. Or keep the Application in manual sync mode until Git is fixed

## 1.3. Image Tags and Immutable Deployments

#### 1.3.0.1. WRONG — mutable tag in production
```console
yaml
image:
  repository: registry.example.com/myapp
  tag: latest    # or "main" or "v1" — all mutable, not reproducible

# WRONG — short SHA (can collide in large repos)
image:
  tag: "abc1234"
```

#### 1.3.0.2. CORRECT — full SHA256 digest (immutable, tamper-evident)
```console
yaml
image:
  repository: registry.example.com/myapp
  tag: "sha256:a3b4c5d6e7f8..."
  
# ALSO CORRECT — full SHA tag (not digest, but still immutable if registry is immutable-tag-enforced)
image:
  tag: "1.4.2-a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8"  # semver + full commit SHA
```
## 1.4. Helm chart versioning discipline:
```console
#Chart.yaml
yaml
version: 1.4.2        # chart version — bump on template changes
appVersion: "2.1.0"   # application version — informational only, not runtime
```
### 1.4.1. Chart version bump triggers:
    MAJOR: values schema breaking change (key renamed, type changed)
    MINOR: new optional feature (new template, new conditional)
    PATCH: bug fix, documentation, non-breaking default change
#### 1.4.1.1. Note: 
  1. Image tag update does NOT bump chart version.
  2. Chart template change MUST bump chart version.
These are independent versioning axes.