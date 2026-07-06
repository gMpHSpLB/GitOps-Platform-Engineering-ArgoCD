# Project: Enterprise Kubernetes Delivery: Helm and ArgoCD

Helm and ArgoCD are complementary, not competing. Helm solves the packaging and parameterisation problem — how to produce correct, environment-specific Kubernetes manifests from a single chart source. ArgoCD solves the delivery and operational control problem — how to ensure the cluster always reflects Git, changes are audited, and drift is detected and remediated continuously.

At enterprise scale, neither alone is sufficient. Helm without ArgoCD requires CI systems to have production cluster credentials, provides no drift detection, and offers weak audit trails. ArgoCD without Helm requires writing environment-specific manifests manually (or using Kustomize as an alternative), which doesn't scale for complex applications.

Together — Helm rendering, ArgoCD reconciling, ESO managing secrets, Kyverno enforcing policies, and Prometheus observing — they form a production-grade Kubernetes delivery platform that satisfies engineering velocity requirements and enterprise compliance requirements simultaneously.

The platform team designs and owns the delivery infrastructure. Developer teams consume it as a self-service capability. This is the modern platform engineering model: you build it, you run it, but the platform makes running it safe by default.

## More Details, please check below:

[Gitops](./README-Gitops.md)

[ArgoCD](./README-ArgoCD.md)

[Resource Relationship](./README-Resource-Relationship.md)

[How Enterprise Works](./README-How-Enterprise-Team_Works.md) 
