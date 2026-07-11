
# 1. Sidecars
A sidecar is an extra container that runs in the same Pod as your main application container 
and supports it with some helper function, such as logging, metrics, proxying, or certificate 
handling. It shares the same network namespace and usually the same volumes as the main container, 
so it can work very closely with the app without changing the app code.

# 2. Why we need sidecars
We use sidecars when the application should stay simple, but we still need extra operational 
features around it. Typical reasons include:

```console
-> log shipping.
-> traffic proxying.
-> service mesh functionality.
-> metrics export.
-> certificate rotation.
-> file synchronization.
```

### 2.0.1. The key idea is separation of concerns: the app does business logic, and the sidecar handles supporting infrastructure tasks.

# 3. Who uses sidecars
Sidecars are commonly used by platform teams, DevOps teams, and service mesh systems. In practice, tools like Istio inject Envoy sidecars automatically, and observability agents may also run as sidecars to collect logs or metrics.

# 4. Who sets them
A sidecar can be:

```console
-> defined directly in the Pod or Deployment YAML by the developer or platform engineer.
->injected automatically by a controller, admission webhook, or service mesh operator.
```
So sometimes the application team writes it, and sometimes the platform layer adds it for you.

## 4.1. Example use case
A common example is log collection:
```console
-> the main app writes logs to a shared volume or stdout,
-> the sidecar reads them and ships them to Elasticsearch, Splunk, or another logging system.
```
### 4.1.1. Another common example is service mesh traffic handling:
```console
the main app listens on its normal port,
the Envoy sidecar intercepts traffic and applies routing, retries, mTLS, or policy.
```