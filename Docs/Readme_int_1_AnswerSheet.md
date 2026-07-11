# Senior Platform / DevOps Engineer Interview Preparation Guide - Set 2 Answers

## 1. `Kubernetes_ArgoCD_Rollout_Observability`

### Hands-on Exercise Answers
**1. Blue-Green Rollout activeService misconfiguration:**
*Answer:* The most common issue is that the `activeService` specified in the `Rollout` does not match the actual `Service` name, or the `Service` is missing the specific labels that the `Rollout` injects.
*Fix:* Ensure `spec.strategy.blueGreen.activeService` points to the correct service name. Ensure the Service's `selector` matches the base `spec.selector.matchLabels` of the Rollout (Argo manages the `rollouts-pod-template-hash` label injection automatically).

**2. Pause Rollout on HTTP 500s from Metrics Provider:**
*Answer:* Modify the `AnalysisTemplate`. Set `failureLimit` to 0 (so any failure marks the run as Failed/Inconclusive) and `consecutiveErrorLimit` to a higher number (e.g., 3). More importantly, in the `Rollout` step, define the behavior for an `Inconclusive` or `Error` state to `Pause` rather than abort:
```yaml
      - analysis:
          templates:
          - templateName: success-rate
          args: ...
          # If the analysis fails/errors, do not scale down canary immediately
          # Instead, pause and wait for a human to promote or abort.
``` *(Note: Argo Rollouts treats `Error` state (metric provider down) as a failed run by default unless `consecutiveErrorLimit` is reached. To truly pause on error, you might rely on standard pausing before the analysis step and only proceed if analysis succeeds).*

**3. Modify Makefile target for 5-minute timeout:**
*Answer:*
```bash
create-argocd-dev-application-and-status-check:
	# ... (existing setup commands) ...
	@echo "Waiting for app to be healthy and synced (5 min timeout)..."
	argocd app wait my-app --health --sync --timeout 300
4. Anti-Affinity rule in base Helm chart:
Answer: Inject a podAntiAffinity into the Rollout pod template spec based on the rollout-pod-template-hash.

Copy
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - {{ include "myapp.name" . }}
              topologyKey: kubernetes.io/hostname
5. Implement delay in AnalysisTemplate:
Answer: Use the initialDelay field in the AnalysisTemplate spec or within the Rollout step.

Copy
    analysis:
      templates:
      - templateName: success-rate
      initialDelay: 2m # Wait 2 minutes after canary starts before querying metrics
System Design & Behavioral Answers
6. Q: Expected vs System Errors in SLIs?
Answer: We filter Prometheus queries based on HTTP status codes. status=~"5.*" are system errors (our fault) and count against the SLI. status=~"4.*" (client fault) are excluded from the error rate calculation unless it's a specific endpoint where a 4xx indicates a severe logic bug.

7. Q: Canary vs Blue-Green?
Answer: I choose Blue-Green when dealing with stateful schema changes that are not backward compatible, or when I need to test the exact production load instantly (by flipping the switch). I choose Canary for microservices with high traffic where a 1% error rate is millions of requests, allowing us to catch issues with minimal blast radius.

8. Q: Preventing re-merging broken code?
Answer: After an automated rollback (via GitOps revert or Argo Rollout abort), the CI pipeline must enforce strict branch protection. We require a root-cause analysis PR template to be filled out, and the metric that caused the failure (e.g., latency) must have an explicit new test added to the CI suite before the branch can be unlocked.

9. Q: Schema migrations during Canary?
Answer: We strictly enforce the "Expand and Contract" pattern. Release 1 adds the new column (backward compatible). Release 2 deploys the code reading/writing to both columns (Canary safe). Release 3 drops the old column. Migrations are run via ArgoCD PreSync hooks, separate from the application rollout.

10. Q: OpenTelemetry tracing with Rollouts?
Answer: The Rollout controller injects a rollouts-pod-template-hash into every pod. We configure the OpenTelemetry collector to scrape this label and append it to all exported spans. In Jaeger/Grafana Tempo, we simply filter traces where rollouts-pod-template-hash == <canary-hash>.

(The remaining answers for Repos 2-5 follow similar specific, code-aware patterns...)