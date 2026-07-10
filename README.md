- [1. Project: - Enterprise Kubernetes Delivery: Helm and ArgoCD](#1-project---enterprise-kubernetes-delivery-helm-and-argocd)
  - [1.1. GitOps Platform Engineering with ArgoCD](#11-gitops-platform-engineering-with-argocd)
    - [1.1.1. Environment: minikube on WSL2, ArgoCD v2.x](#111-environment-minikube-on-wsl2-argocd-v2x)
  - [1.2. bin/argocd version](#12-binargocd-version)
  - [1.3. helm version](#13-helm-version)
  - [1.4. kubectl version](#14-kubectl-version)
  - [1.5. What I built:](#15-what-i-built)
  - [1.6. Key skills demonstrated:](#16-key-skills-demonstrated)
  - [1.7. More Details, please check below:](#17-more-details-please-check-below)
    - [1.7.1. Gitops](#171-gitops)
    - [1.7.2. ArgoCD](#172-argocd)
      - [1.7.2.1. ArgoCD Enterprise Architecture](#1721-argocd-enterprise-architecture)
      - [1.7.2.2. ArgoCD App Of Apps Pattern](#1722-argocd-app-of-apps-pattern)
    - [1.7.3. Resource Relationship](#173-resource-relationship)
      - [1.7.3.1. Tool kubectl Helm ArgoCD](#1731-tool-kubectl-helm-argocd)
      - [1.7.3.2. Selectors in Kubernetes](#1732-selectors-in-kubernetes)
      - [1.7.3.3  Kubernetes Annotations](#1733--kubernetes-annotations)
    - [1.7.4. How Enterprise Works](#174-how-enterprise-works)

# 1. Project: - Enterprise Kubernetes Delivery: Helm and ArgoCD
## 1.1. GitOps Platform Engineering with ArgoCD
### 1.1.1. Environment: minikube on WSL2, ArgoCD v2.x

## 1.2. bin/argocd version
```console
  argocd: v3.4.4+443415b
    BuildDate: 2026-06-18T09:15:00Z
    GitCommit: 443415b5527ac55366e0760c93ef0e1abd0cf273
    GitTreeState: clean
    GoVersion: go1.26.0
    Compiler: gc
    Platform: linux/amd64
  argocd-server: v3.4.4
    BuildDate: 2026-06-18T08:48:48Z
    GitCommit: 443415b5527ac55366e0760c93ef0e1abd0cf273
    GitTreeState: clean
    GitTag: v3.4.4
    GoVersion: go1.26.0
    Compiler: gc
    Platform: linux/amd64
    Kustomize Version: v5.8.1 2026-02-09T16:15:27Z
    Helm Version: v3.19.4+g7cfb6e4
    Kubectl Version: v0.34.0
    Jsonnet Version: v0.21.0
```

## 1.3. helm version
```console
    version.BuildInfo{Version:"v3.18.6", GitCommit:"b76a950f6835474e0906b96c9ec68a2eff3a6430", GitTreeState:"clean", GoVersion:"go1.24.6"}
```

## 1.4. kubectl version
```console
    Client Version: v1.36.2
    Kustomize Version: v5.8.1
    Server Version: v1.35.4
```

## 1.5. What I built:
  - Production-configured ArgoCD instance with annotation-based resource tracking,
    hardened server configuration, and proper credential management
  - ArgoCD Application managing myapp Helm chart across dev/staging environments
    with full sync policy configuration: automated sync, selfHeal, prune, retry
  - Demonstrated and explained the GitOps contract: any manual kubectl change
    to a managed resource is detected and reverted within one reconciliation cycle
  - Implemented App of Apps pattern for managing multiple Application objects
    from a single Git source
  - Diagnosed and resolved five production-equivalent ArgoCD failure scenarios:
    ComparisonError, SyncFailed, OutOfSync-with-no-diff, Synced+Degraded,
    and prune-deleted-unmanaged-resource

## 1.6. Key skills demonstrated:
  - ArgoCD internal architecture: repo-server, application-controller,
    argocd-server, redis — what each does and what breaks when each fails
  - Sync status vs Health status — the two independent dimensions and
    every meaningful combination
  - Sync wave ordering for resource creation dependencies
  - ArgoCD finalizer mechanics and cascade delete behaviour
  - Self-healing mechanics: watch events vs periodic reconciliation
  - Multi-application namespace conflicts and how to prevent them

Helm and ArgoCD are complementary, not competing. Helm solves the packaging and parameterisation problem — how to produce correct, environment-specific Kubernetes manifests from a single chart source. ArgoCD solves the delivery and operational control problem — how to ensure the cluster always reflects Git, changes are audited, and drift is detected and remediated continuously.

At enterprise scale, neither alone is sufficient. Helm without ArgoCD requires CI systems to have production cluster credentials, provides no drift detection, and offers weak audit trails. ArgoCD without Helm requires writing environment-specific manifests manually (or using Kustomize as an alternative), which doesn't scale for complex applications.

Together — Helm rendering, ArgoCD reconciling, ESO managing secrets, Kyverno enforcing policies, and Prometheus observing — they form a production-grade Kubernetes delivery platform that satisfies engineering velocity requirements and enterprise compliance requirements simultaneously.

The platform team designs and owns the delivery infrastructure. Developer teams consume it as a self-service capability. This is the modern platform engineering model: you build it, you run it, but the platform makes running it safe by default.

## 1.7. More Details, please check below:

### 1.7.1. [Gitops](./README-Gitops.md)

### 1.7.2. [ArgoCD](./README-ArgoCD.md)

#### 1.7.2.1. [ArgoCD Enterprise Architecture](./README-ArgoCD-Enterprise-Architecture-Guide.md) 
#### 1.7.2.2. [ArgoCD App Of Apps Pattern](./README-ArgoCD_App_of_Apps_Patterns.md)

### 1.7.3. [Resource Relationship](./README-Resource-Relationship.md)
   
#### 1.7.3.1. [Tool kubectl Helm ArgoCD](./README-Tooling-Comparison-kubectl-Helm-ArgoCD.md)
#### 1.7.3.2. [Selectors in Kubernetes](./README-Selectors-in-Kubernetes.md)
#### 1.7.3.3  [Kubernetes Annotations](./README-Kubernetes%20Annotations.md) 
      
### 1.7.4. [How Enterprise Works](./README-How-Enterprise-Team_Works.md) 
