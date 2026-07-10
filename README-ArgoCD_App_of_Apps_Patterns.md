# 1. App of Apps Pattern
## 1.1. What Problem It Solves
Without App of Apps: a platform engineer must manually kubectl apply each Application CR when onboarding a new team or adding a new environment. This is manual toil and does not scale.

## 1.2. With App of Apps: 
A single root Application watches a Git directory containing Application manifests. Adding a new application means committing a new Application YAML to Git. ArgoCD discovers and creates it automatically. Everything is declarative and auditable.

## 1.3. Enterprise Structure
```console
      gitops-repo/
      ├── root-app.yaml                    ← The root Application (bootstraps everything)
      ├── platform/
      │   ├── monitoring-app.yaml          ← Application for Prometheus/Grafana stack
      │   ├── ingress-app.yaml             ← Application for nginx ingress controller
      │   ├── cert-manager-app.yaml        ← Application for cert-manager
      │   └── vault-app.yaml               ← Application for HashiCorp Vault
      ├── teams/
      │   ├── myapp-team/
      │   │   ├── myapp-dev.yaml           ← Application for myapp in dev
      │   │   ├── myapp-staging.yaml       ← Application for myapp in staging
      │   │   └── myapp-prod.yaml          ← Application for myapp in prod
      │   └── myai-team/
      │       ├── myaiapp-dev.yaml
      │       └── myaiapp-prod.yaml
      └── projects/
          ├── myapp-project.yaml           ← AppProject for myapp team
          └── myai-project.yaml            ← AppProject for myai team
```
## 1.4. root-app.yaml — the bootstrap Application
```console
      yaml# root-app.yaml — the bootstrap Application
      # This is the ONLY Application created manually (once, during cluster bootstrap)
      apiVersion: argoproj.io/v1alpha1
      kind: Application
      metadata:
        name: root-app
        namespace: argocd
        finalizers:
          - resources-finalizer.argocd.argoproj.io
      spec:
        project: default
        source:
          repoURL: https://github.com/org/gitops-repo
          targetRevision: main
          path: .   # watches the entire repo for Application manifests
          directory:
            recurse: true   # scan subdirectories
            include: "*.yaml"
            exclude: "root-app.yaml"  # don't watch itself
        destination:
          server: https://kubernetes.default.svc
          namespace: argocd   # Applications land in argocd namespace
        syncPolicy:
          automated:
            prune: true
            selfHeal: true
          syncOptions:
            - CreateNamespace=false   # argocd namespace already exists
```
## 1.5. When App of Apps is the right pattern:

Platform team manages >5 applications across multiple environments
New application onboarding should be self-service (PR to add YAML file)
ArgoCD itself needs to manage its own configuration (meta-management)
Multi-cluster fleet requires consistent application delivery

## 1.6. When App of Apps is overkill:

Single team, single application, single environment
Early-stage project where overhead isn't justified
Use ApplicationSets instead when the pattern is purely generative