# Resource Relationship Map

+-------------------+-------------------------+-------------------------+----------------------------+-------------------+
| Resource          | Created by              | Consumed by             | Connects to               | Required          |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| App source code   | Developer               | CI pipeline             | Docker image (via build)  | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Docker image      | CI (build + push)       | Kubelet                 | Registry, Pod spec        | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Helm chart        | Dev / platform team     | Helm CLI, ArgoCD        | values, templates         | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| values-{env}.yaml | Developer / ops         | Helm template engine    | chart defaults            | Per env           |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Manifests         | Helm or ArgoCD          | Kubernetes API server   | All K8s objects           | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Namespace         | Platform / ArgoCD       | Namespaced resources    | RBAC, NetPol, quotas      | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| ServiceAccount    | Helm template           | Pod spec                | RBAC subject              | Best practice     |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| ConfigMap         | Helm template           | Pod                     | Deployment spec           | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Secret            | Helm or ESO             | Pod, Ingress TLS        | External secret store     | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Deployment        | Helm template           | ReplicaSet controller   | Pod tmpl, CM, Secret, SA  | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| ReplicaSet        | Deployment controller   | Pod controller          | Pod template              | Auto-created      |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Pod               | ReplicaSet controller   | Kubelet                 | CM, Secret, SA, image     | Auto-created      |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Service           | Helm template           | kube-proxy, Ingress     | Pod selector              | Yes               |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Ingress           | Helm template           | Ingress controller      | Service, TLS secret       | If external traffic|
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| HPA               | Helm template           | HPA controller          | Deployment, metrics-server| Prod only         |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| PDB               | Helm template           | Disruption controller   | Pod selector              | Prod only         |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| NetworkPolicy     | Helm template           | CNI plugin              | Pod, NS selector          | Security          |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| RBAC              | Platform / Helm         | API server              | ServiceAccount            | Security          |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| PVC               | Helm template           | Pod                     | StorageClass, PV          | Stateful only     |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Helm Release      | Helm CLI                | Helm CLI                | Release Secret            | Helm-only         |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| ArgoCD App        | Platform engineer (Git) | ArgoCD app-controller   | Git repo, cluster         | ArgoCD only       |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| AppProject        | Platform admin          | ArgoCD Application      | RBAC, cluster whitelist   | Enterprise        |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Sync policy       | ArgoCD Application spec | app-controller          | Git -> cluster            | ArgoCD only       |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Git repository    | Developer / ops         | CI, ArgoCD repo-server  | Source + manifests        | Both              |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
| Cluster dest      | Platform admin          | ArgoCD Application      | Target API server URL     | ArgoCD only       |
+-------------------+-------------------------+-------------------------+---------------------------+-------------------+
