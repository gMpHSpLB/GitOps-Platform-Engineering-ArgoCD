# Senior Platform / DevOps Engineer Interview Preparation Guide - Set 2

This guide is dynamically generated based on your workspace repositories:
- `Kubernetes_ArgoCD_Rollout_Observability`
- `GitOps-Platform-Engineering-ArgoCD`
- `Gitops-Argocd`
- `Helm-Chart-Engineering`
- `Helm-Charts-Packaging-Releasing`

## 1. `Kubernetes_ArgoCD_Rollout_Observability` (10 Questions)

**Hands-on Exercises**
1. **Exercise (30 mins):** A Blue-Green rollout successfully scales up the new version, but the `activeService` fails to switch traffic over. Identify and fix the misconfiguration in the `Rollout` CRD and the associated `Service` selectors.
2. **Exercise (45 mins):** Your Datadog/Prometheus endpoint for the `AnalysisTemplate` is temporarily returning HTTP 500s. Configure the `Rollout` so that it pauses for manual intervention instead of automatically rolling back or failing open.
3. **Exercise (30 mins):** Modify the `Makefile` target `create-argocd-dev-application-and-status-check` to include a strict 5-minute timeout. If the application isn't completely `Healthy` and `Synced` by then, the command must fail and exit with code 1.
4. **Exercise (45 mins):** Implement an Anti-Affinity rule in the base Helm chart to ensure that the Canary replicas are never scheduled on the same Kubernetes nodes as the Stable replicas during a rollout.
5. **Exercise (30 mins):** The `AnalysisRun` keeps failing because it's querying metrics too soon before the new pod is actually ready to receive traffic. Implement a `delay` in the `AnalysisTemplate`.

**System Design & Behavioral**
6. **Q:** "How do you distinguish between 'Expected Errors' (like 404s from web crawlers) and 'System Errors' (like 500s) when creating success-rate SLIs for automated rollbacks?"
7. **Q:** "Explain a scenario where you would intentionally choose a Canary deployment over a Blue-Green deployment, and vice versa."
8. **Q:** "If an automated rollback occurs, how do you prevent developers from merging the exact same broken code again an hour later?"
9. **Q:** "How do you handle schema migrations in a database during a progressive Canary rollout where both the old and new code are running simultaneously?"
10. **Q:** "Walk me through how you integrate OpenTelemetry tracing with Argo Rollouts so that you can trace requests specifically routed to the canary pods."

---

## 2. `GitOps-Platform-Engineering-ArgoCD` (10 Questions)

**Hands-on Exercises**
11. **Exercise (45 mins):** Write an `ApplicationSet` using the Cluster Generator that deploys a specific baseline security policy (e.g., Kyverno or OPA Gatekeeper) only to clusters with the label `compliance=pci`.
12. **Exercise (30 mins):** The App of Apps root application is out of sync because one of the child applications failed to apply due to a schema validation error. Configure the root app to ignore the sync status of that specific child temporarily.
13. **Exercise (30 mins):** Secure the ArgoCD server installation. Provide the patch to disable insecure mode (`--insecure`) and mandate TLS.
14. **Exercise (45 mins):** Configure ArgoCD RBAC in the `argocd-rbac-cm` ConfigMap to grant a specific GitHub team (`Platform-SREs`) admin access, while granting `Developers` read-only access.
15. **Exercise (30 mins):** You need to migrate the ArgoCD cluster. Export the current state of ArgoCD (secrets, repo credentials, and projects) to be safely imported into a new cluster.

**System Design & Behavioral**
16. **Q:** "Describe your strategy for managing the 'App of Apps' repository structure. How do you prevent a single bad commit in the root app from destroying all clusters?"
17. **Q:** "How do you handle Kubernetes version upgrades in a strictly GitOps-managed environment?"
18. **Q:** "What is your approach to secret management in GitOps? Compare External Secrets Operator vs Sealed Secrets."
19. **Q:** "Explain the blast radius implications of managing multiple production clusters from a single centralized ArgoCD instance versus having ArgoCD installed in every cluster."
20. **Q:** "Walk me through a disaster recovery scenario where the Git repository hosting your platform manifests is deleted or inaccessible."

---

## 3. `Gitops-Argocd` (10 Questions)

**Hands-on Exercises**
21. **Exercise (30 mins):** Developers complain their app is stuck `Out of Sync`. You notice a `MutatingAdmissionWebhook` is injecting a sidecar container, causing drift. Fix this using `ignoreDifferences`.
22. **Exercise (45 mins):** Implement Sync Waves. Ensure that a PostgreSQL database (Wave -1) is fully deployed and healthy before the backend API (Wave 0) is deployed.
23. **Exercise (30 mins):** Create a Pre-Sync hook that runs a Job to perform a database backup before a new version of an application is synced.
24. **Exercise (30 mins):** Set up automated pruning for a development environment but ensure that a specific `StatefulSet` (like a Redis cache) is protected from deletion via annotations.
25. **Exercise (45 mins):** Configure ArgoCD to use Helm's `valueFiles` dynamically based on the target cluster's name using environment variables in the AppSet.

**System Design & Behavioral**
26. **Q:** "When should developers have access to the ArgoCD UI, and when should they rely entirely on Git PR checks?"
27. **Q:** "How do you manage configuration drift when someone uses `kubectl edit` directly on the cluster in an emergency?"
28. **Q:** "Explain how you handle ephemeral testing environments (e.g., creating a whole namespace and app stack per PR) using ArgoCD."
29. **Q:** "What are the risks of enabling `selfHeal` and `prune: true` in production environments?"
30. **Q:** "How do you architect your Git repository branching strategy to map to different environments (e.g., dev, staging, prod)?"

---

## 4. `Helm-Chart-Engineering` (10 Questions)

**Hands-on Exercises**
31. **Exercise (45 mins):** Write a complex Helm `_helpers.tpl` template that dynamically generates a set of environment variables based on a dictionary passed in `values.yaml`.
32. **Exercise (30 mins):** Implement `values.schema.json` to strictly require that `resources.requests.cpu` is always defined and must be a string matching a regex (e.g., `^[0-9]+m$`).
33. **Exercise (30 mins):** Modify a chart to support optionally generating an Ingress resource based on a boolean flag (`ingress.enabled`), and support both `networking.k8s.io/v1beta1` and `v1` API versions based on cluster capabilities.
34. **Exercise (45 mins):** Extract common labels and annotations into a "Library Chart" and demonstrate how to include and utilize this library chart as a dependency in a standard application chart.
35. **Exercise (30 mins):** Add Helm unit tests using the `helm plugin install https://github.com/quintush/helm-unittest` pattern to verify that the Service is exposed as a `ClusterIP` when `type` is not specified.

**System Design & Behavioral**
36. **Q:** "What are the trade-offs of using one 'Umbrella Chart' for all microservices versus creating separate, independent charts for each service?"
37. **Q:** "How do you enforce standardization across 100+ microservices so that every team includes standardized logging and monitoring sidecars?"
38. **Q:** "Explain your strategy for deprecating an old version of a Helm chart that is still being used by multiple teams."
39. **Q:** "What is the most complex templating issue you've faced with Helm, and how did you resolve it without making the chart unreadable?"
40. **Q:** "How do you handle secret injection in Helm templates without hardcoding base64 strings into Git?"

---

## 5. `Helm-Charts-Packaging-Releasing` (10 Questions)

**Hands-on Exercises**
41. **Exercise (45 mins):** Refactor the GitHub Actions workflow. Currently, it runs `helm package` on every commit. Change it to only trigger a package and push if the `version` string in `Chart.yaml` has been incremented compared to the `main` branch.
42. **Exercise (30 mins):** Implement a step in the CI pipeline that spins up a `kind` (Kubernetes in Docker) cluster, installs the chart, and runs `helm test` before allowing the PR to merge.
43. **Exercise (45 mins):** Integrate `trivy` into the CI pipeline to scan the generated Helm manifests for misconfigurations (like running as root) and fail the build if CRITICAL vulnerabilities are found.
44. **Exercise (30 mins):** Update the Makefile to push the packaged `.tgz` file to an OCI-compliant registry (like GitHub Container Registry or Harbor) instead of a traditional ChartMuseum repository.
45. **Exercise (30 mins):** Implement artifact signing. Add a step to the GitHub Action to sign the Helm chart using Cosign and verify it.

**System Design & Behavioral**
46. **Q:** "Walk me through a secure software supply chain for Helm charts from the developer's laptop to production deployment."
47. **Q:** "How do you handle versioning conflicts when multiple developers are updating the same Helm chart simultaneously?"
48. **Q:** "Why would you choose to store Helm charts in an OCI registry instead of a standard HTTP server?"
49. **Q:** "Explain how you manage the lifecycle of container images referenced within your Helm charts. Do you hardcode the image tag in `values.yaml` or pass it in during deployment?"
50. **Q:** "What metrics or SLIs do you track to measure the health and efficiency of your CI/CD pipelines?"