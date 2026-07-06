# Best Practices and Enterprise Recommendations

## Three-Environment Architecture: Sample Design
```console
Repository structure:
  ├── app-repo/
  │   ├── src/                    ← application source
  │   ├── Dockerfile
  │   ├── charts/myapp/           ← Helm chart
  │   └── .github/workflows/ci.yaml
  │
  └── gitops-repo/
      ├── applications/
      │   ├── root-app.yaml       ← App of Apps root
      │   ├── myapp-dev.yaml      ← Application CR
      │   ├── myapp-staging.yaml  ← Application CR
      │   └── myapp-prod.yaml     ← Application CR
      ├── envs/
      │   ├── dev/
      │   │   └── values.yaml     ← dev overrides
      │   ├── staging/
      │   │   └── values.yaml     ← staging overrides
      │   └── prod/
      │       └── values.yaml     ← prod overrides
      └── projects/
          └── myapp-project.yaml  ← AppProject (RBAC boundary)
```

## Separation of Responsibilities
```console
+--------------+------------------------------------+------------------------------+
| Team         | Responsibility                     | Tools                        |
+--------------+------------------------------------+------------------------------+
| Developer    | Application code, Helm chart,      | Git, CI                      |
|              | unit tests                         |                              |
+--------------+------------------------------------+------------------------------+
| Platform /   | ArgoCD, cluster infrastructure,    | ArgoCD, Terraform            |
| SRE          | RBAC, GitOps repo                  |                              |
+--------------+------------------------------------+------------------------------+
| Security     | Image signing policy, Kyverno      | Cosign, Vault, Kyverno       |
|              | policies, secret stores            |                              |
+--------------+------------------------------------+------------------------------+
| Operations   | Monitoring alerts, on-call         | Grafana, PagerDuty           |
|              | runbooks, incident response        |                              |
+--------------+------------------------------------+------------------------------+
```
### GitOps enforces this separation structurally:
```console 
   - developers push to the app repo, 
   - platform engineers manage the GitOps repo structure.
```
Neither has direct prod cluster access.

## Common Mistakes
+----------------------------------+----------------------------------+----------------------------------+
| Mistake                          | Consequence                      | Fix                              |
+----------------------------------+----------------------------------+----------------------------------+
| Secrets in Git                   | Permanent security breach        | External Secrets Operator + Vault |
+----------------------------------+----------------------------------+----------------------------------+
| Using latest image tag           | Undeterministic deployments,     | Pin to SHA or immutable tag       |
|                                  | no rollback                      |                                  |
+----------------------------------+----------------------------------+----------------------------------+
| helm upgrade without helm diff   | Surprise production changes      | Mandate helm diff in runbook      |
+----------------------------------+----------------------------------+----------------------------------+
| Single values file for all envs   | Dev relaxed settings leak to prod| Separate values file per env      |
+----------------------------------+----------------------------------+----------------------------------+
| No PDB in production             | Node drain kills all pods        | minAvailable: replicas - 1       |
|                                  | simultaneously                   |                                  |
+----------------------------------+----------------------------------+----------------------------------+
| selfHeal: true in prod           | Automated rollback of manual     | selfHeal: false in prod, alert    |
|                                  | emergency fix                    | on drift                          |
+----------------------------------+----------------------------------+----------------------------------+
| App code and GitOps manifests     | CI/CD coupling, signal-to-noise  | Separate repositories             |
| in same repo                     | in history                       |                                  |
+----------------------------------+----------------------------------+----------------------------------+
| ArgoCD managing its own namespace | Bootstrap circular dependency    | Manage ArgoCD via Terraform or    |
|                                  |                                  | separate manifest                 |
+----------------------------------+----------------------------------+----------------------------------+
| No --history-max on helm upgrade  | Release Secrets accumulate,      | --history-max 10 in CI            |
|                                  | etcd grows                       |                                  |
+----------------------------------+----------------------------------+----------------------------------+
| Helm --atomic disabled in CI      | FAILED releases block            | Always use --atomic in CI        |
|                                  | subsequent deployments           | pipelines                         |
+----------------------------------+----------------------------------+----------------------------------+

## Secret Management Approaches
```console
+-------------------------+----------------------------+-------------+-----------------------------+
| Approach                | Tool                       | Maturity    | When to use                 |
+-------------------------+----------------------------+-------------+-----------------------------+
| External Secrets        | ESO + Vault / AWS SM /     | Production  | Enterprise — secrets never  |
| Operator (ESO)          | GCP SM                     | standard    | in Git                      |
+-------------------------+----------------------------+-------------+-----------------------------+
| Sealed Secrets          | Bitnami sealed-secrets     | Simple      | Small teams, no Vault       |
+-------------------------+----------------------------+-------------+-----------------------------+
| Helm Secrets plugin     | helm-secrets (sops)        | Medium      | Teams already using SOPS    |
+-------------------------+----------------------------+-------------+-----------------------------+
| Vault Agent Sidecar     | Vault                      | Complex     | When Vault is mandatory     |
|                         |                            |             | (compliance)                |
+-------------------------+----------------------------+-------------+-----------------------------+
| Plain K8s Secret in Git | None                       | Never       | Development only, never     |
|                         |                            |             | production                  |
+-------------------------+----------------------------+-------------+-----------------------------+
```
### ESO is the recommended enterprise approach (2024+). 
It integrates cleanly with ArgoCD: the GitOps repo stores ExternalSecret CRs (safe to commit), and 
ESO syncs actual secret values from Vault into the cluster at runtime.

## Environment Promotion Strategy

```console
Environments:          dev → staging → prod
Git branches:          feature/* → main → (tag v1.2.3)
Image tags:            commit-sha → commit-sha → v1.2.3
ArgoCD sync policy:    automated → manual → manual + AppProject RBAC
Approval gates:        none → PR review → Change Advisory Board (CAB)
Rollback authority:    developer → platform engineer → SRE on-call
```

## When to Choose Helm Alone vs Helm + ArgoCD
```console
+-----------------------------------------------+--------------------------------------+
| Scenario                                      | Recommendation                       |
+-----------------------------------------------+--------------------------------------+
| Single developer, simple app, no compliance   | Helm alone is sufficient             |
| requirements                                  |                                      |
+-----------------------------------------------+--------------------------------------+
| Multiple developers, multiple environments,   | Helm + ArgoCD                        |
| audit trail needed                            |                                      |
+-----------------------------------------------+--------------------------------------+
| Multiple teams deploying to shared cluster    | Helm + ArgoCD + AppProjects          |
+-----------------------------------------------+--------------------------------------+
| Regulated industry (finance, healthcare,      | Helm + ArgoCD + ESO + Kyverno        |
| government)                                   |                                      |
+-----------------------------------------------+--------------------------------------+
| Multiple clusters, fleet management            | Helm + ArgoCD multi-cluster +        |
|                                               | ApplicationSets                      |
+-----------------------------------------------+--------------------------------------+
| Air-gapped environment                        | Helm (packaged charts) + ArgoCD      |
|                                               | (with mirrored repos)                |
+-----------------------------------------------+--------------------------------------+
```
## Platform Team Delivery Model
```console
Platform team responsibilities:
  ├── Cluster infrastructure (Terraform)
  ├── ArgoCD installation and configuration
  ├── AppProject definitions (team RBAC boundaries)
  ├── Base Helm charts (golden path)
  ├── Secret management (ESO + Vault)
  ├── NetworkPolicy templates
  ├── LimitRange and ResourceQuota per namespace
  ├── Kyverno policies (policy as code)
  └── Observability stack (Prometheus, Grafana, Loki)

Developer team responsibilities:
  ├── Application Helm chart (extending golden path)
  ├── values-{env}.yaml (application-specific)
  ├── CI pipeline (build, test, image push, tag update)
  └── Application-specific alerting rules

Separation enforced by:
  ├── ArgoCD AppProjects (team A cannot deploy to team B's namespace)
  ├── Git branch protection (platform repo requires platform team review)
  ├── Kyverno policies (developers cannot bypass security controls)
  └── RBAC (developers have read-only cluster access, not kubectl apply)
```

  ## Observability Considerations

```console
   ### Every Helm chart should include these for enterprise observability:

   1. Prometheus scrape annotations (or ServiceMonitor CRD)
      podAnnotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "8000"
      prometheus.io/path: "/metrics"

   2. Structured JSON logging (configured in app, not chart)
      LOG_FORMAT: json — so Loki can parse and query log fields

   3. Resource metrics for HPA
      resources:
      requests:
         cpu: "100m"    # Required for HPA CPU metrics
         memory: "128Mi"  # Required for HPA memory metrics

   4. Readiness probe that reflects real service health (not just "alive")
      readinessProbe:
      httpGet:
         path: /ready  # Should return 503 if dependencies are down
      #NOT /health or / — those typically return 200 even when degraded

   5. ArgoCD sync status in alerting
      Add Prometheus rules that alert on:
      argocd_app_info{sync_status!="Synced"} > 0  (drift alert)
      argocd_app_info{health_status!="Healthy"} > 0 (health alert)
```
## Testing Strategy
+---------------------+-------------------------+------------------+------------------------------+
| Test type           | Tool                    | When             | What it validates            |
+---------------------+-------------------------+------------------+------------------------------+
| Chart unit tests    | helm-unittest           | CI (pre-apply)   | Template rendering correctness|
+---------------------+-------------------------+------------------+------------------------------+
| Helm lint           | helm lint --strict      | CI (pre-apply)   | Syntax and best practices     |
+---------------------+-------------------------+------------------+------------------------------+
| Manifest validation | kubeconform / kubeval   | CI (pre-apply)   | Kubernetes API schema         |
|                     |                         |                  | conformance                   |
+---------------------+-------------------------+------------------+------------------------------+
| Policy validation   | conftest + OPA policies | CI (pre-apply)   | Security and compliance rules |
+---------------------+-------------------------+------------------+------------------------------+
| Helm test           | helm test               | Post-deploy      | Service connectivity, basic   |
|                     |                         |                  | smoke                         |
+---------------------+-------------------------+------------------+------------------------------+
| Integration tests   | k6 / pytest against live| Post-deploy      | Application behavior          |
|                     | cluster                 | staging          |                              |
+---------------------+-------------------------+------------------+------------------------------+
| Chaos testing       | Chaos Mesh / LitmusChaos| Pre-prod gate    | Failure recovery              |
+---------------------+-------------------------+------------------+------------------------------+