
# ArgoCD and Kubernetes Application Delivery
## Enterprise Architecture Guide — Portfolio Edition
### Versions: ArgoCD 3.4+, Kubernetes 1.31+, Helm 3.16+
### Audience: Platform engineers, SREs, senior developers
An ArgoCD Application is a Kubernetes custom resource of kind Application in the argoproj.io/v1alpha1 API group. It is a pointer — it points from a Git source to a cluster destination and declares how to render the manifests in between. It does not contain your workload. It is not your workload. It is the relationship between a Git path and a cluster namespace.

## The ArgoCD Application Model

```console
ArgoCD Application (CRD in argocd namespace)
│
├── spec.source → Git repo + path + revision + render method (Helm/Kustomize/plain)
├── spec.destination → cluster API server URL + target namespace
├── spec.syncPolicy → automated/manual, prune, selfHeal, syncOptions
└── status → sync status + health status + resource list
```
## What is CRD , Application CRs and AppProject CRs
```console
A CRD is a Kubernetes schema that defines a new kind of API object, while a CR is an actual instance of that new object. In Argo CD, Application and AppProject are both Custom Resources built on top of Argo CD’s CRDs, so you create YAML objects of those kinds just like you create Deployments or Services.

### CRD
A Custom Resource Definition tells Kubernetes, “this new kind of object exists.” It adds a new API type to the cluster, with its own schema, validation, and lifecycle rules. Without the CRD installed, Kubernetes will not understand the related custom objects.

### CR
A Custom Resource is one actual object created from that CRD. For example, an Argo CD Application object is a CR, and an AppProject object is also a CR. These are stored in the Kubernetes API and managed by controllers, just like native resources are.

### Argo CD examples
1. Application CR: defines what to deploy, from which repo, to which cluster, and in which namespace.
2. AppProject CR: 
   - An AppProject is an ArgoCD governance boundary. 
   - It defines the security and access boundary for a set of Applications, including allowed repositories, destinations, and resource permissions.
   - It has no effect on runtime behaviour once the resources are created.

```console
      #YAML
      apiVersion: argoproj.io/v1alpha1
      kind: AppProject
      metadata:
      name: myapp-team
      namespace: argocd
      spec:
      description: "myapp team — dev/staging/prod"
      
      # Which repos Applications in this project can source from
      sourceRepos:
         - https://github.com/org/myapp-gitops
      
      # Which cluster+namespace combinations are valid destinations
      destinations:
         - server: https://kubernetes.default.svc
            namespace: myapp-*   # wildcard — dev, staging, prod
      
      # Cluster-scoped resources this project's apps can create
      clusterResourceWhitelist:
         - group: ""
            kind: Namespace
      
      # Namespace-scoped resources this project's apps CANNOT create
      # (platform team controls these — team cannot override)
      namespaceResourceBlacklist:
         - group: ""
            kind: ResourceQuota
         - group: ""
            kind: LimitRange
      
      # Sync window: production syncs only Tue/Thu 10am-2pm UTC
      syncWindows:
         - kind: allow
            schedule: "0 10 * * 2,4"
            duration: 4h
            namespaces: ["myapp-prod"]
            manualSync: true
```

### Simple analogy
CRD = the blueprint for a new object type.
CR = one real object created from that blueprint.

So in Argo CD:
 - The CRD enables Application and AppProject,
 - The CRs are the actual YAML definitions you apply to manage deployments and policy.

## Namespace Understanding: 
A namespace is a runtime isolation boundary. Pods, Services, and secrets in namespace A cannot see those in namespace B without explicit NetworkPolicy or RBAC.

1. Developer App Namespace per Environment: 
Your actual application — myapp, the FastAPI service, the Deployment, Service, ConfigMap — lives in myapp-dev, myapp-staging, or myapp-prod. 
2. ArgoCD application Namespace: 
The ArgoCD Application object lives in the argocd namespace. 

### Why separate namespaces: These are deliberately separate for the following reasons:

| Concern              | ArgoCD namespace                              | Workload namespace                      |
|----------------------|-----------------------------------------------|-----------------------------------------|
| RBAC boundary        | Platform team manages                         | Developer team manages                  |
| Secret visibility    | ArgoCD repo credentials, cluster secrets      | Application secrets                     |
| Blast radius         | Platform-level failure                        | Single application failure              |
| Audit trail          | All sync operations                           | Only resource changes                   |
| ArgoCD upgrade       | Affects only argocd namespace                 | Zero impact on running workloads        |

When to use which namespace:
1. When to use argocd namespace: 
ArgoCD Application CRs, AppProject CRs, ArgoCD Repository credentials, ArgoCD cluster credentials. Nothing else.

2. When to use the workload namespace: 
Every resource your application needs at runtime — Deployment, Service, ConfigMap, Secret, Ingress, HPA, PDB, NetworkPolicy, ServiceAccount.

## Core Delivery Model
The Complete Path: Source Code to Running Container

```console
            Developer writes Python/Go code
                     │
                     ▼
            Git commit → app-repo (src/ + Dockerfile + charts/)
                     │
                     ▼
            CI Pipeline (GitHub Actions / GitLab CI)
            ├── Unit tests, lint, SAST
            ├── docker build --build-arg GIT_SHA=${{ github.sha }}
            ├── trivy image scan (block on CRITICAL CVEs)
            ├── cosign sign (keyless via OIDC)
            ├── docker push registry.example.com/myapp:$GIT_SHA
            ├── syft generate SBOM → attest to registry
            └── git commit "chore: bump image to $GIT_SHA" → gitops-repo
                     │
                     ▼
            GitOps Repo (gitops-repo)
            └── envs/dev/values.yaml: image.tag: $GIT_SHA
                     │
                     ▼
            ArgoCD repo-server (detects new commit via webhook or 180s poll)
            └── helm template myapp ./charts/myapp -f values.yaml -f envs/dev/values.yaml
                     │
                     ▼
            ArgoCD application-controller
            ├── Compares rendered manifest (desired) vs cluster state (actual)
            ├── Finds diff: image tag changed
            └── Triggers sync (if automated) or marks OutOfSync (if manual)
                     │
                     ▼
            kubectl apply (executed by argocd-server)
            └── Deployment.spec.template.spec.containers[0].image updated
                     │
                     ▼
            Kubernetes Deployment controller
            └── Creates new ReplicaSet → Pods → kubelet pulls image → containers start
                     │
                     ▼
            Application running: myapp:$GIT_SHA serving traffic
```
### Relationship summary:

| Layer            | Entity                | Created by             | Lives where         |
|------------------|-----------------------|------------------------|---------------------|
| Source           | Python/Go files       | Developer              | Git app-repo        |
| Artefact         | Docker image          | CI (docker build)      | Container registry  |
| Configuration    | Helm chart + values   | Developer / Platform   | Git gitops-repo     |
| Declaration      | ArgoCD Application CR | Platform engineer      | argocd namespace    |
| Runtime          | Deployment, Pods      | Kubernetes controllers | myapp-dev namespace |
| Identity         | ServiceAccount        | Helm chart template    | myapp-dev namespace |
| Config injection | ConfigMap, Secret     | Helm / ESO             | myapp-dev namespace |
| Traffic          | Service, Ingress      | Helm chart template    | myapp-dev namespace |
| Scaling          | HPA, PDB              | Helm chart template    | myapp-dev namespace |



