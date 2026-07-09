# Project: - Enterprise Kubernetes Delivery: Helm and ArgoCD
## GitOps Platform Engineering with ArgoCD
### Environment: minikube on WSL2, ArgoCD v2.x
What I built:
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

Key skills demonstrated:
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

## More Details, please check below:

[Gitops](./README-Gitops.md)

[ArgoCD](./README-ArgoCD.md)

[Resource Relationship](./README-Resource-Relationship.md)

[How Enterprise Works](./README-How-Enterprise-Team_Works.md) 
