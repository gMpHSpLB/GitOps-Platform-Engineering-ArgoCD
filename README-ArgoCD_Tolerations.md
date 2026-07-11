# Tolerations
A toleration is a Pod setting that allows the Pod to be scheduled onto a node 
that has a matching taint. Taints are applied to nodes to repel Pods, and tolerations 
are applied to Pods to say “this Pod is allowed here anyway.”

## Why we need tolerations
We need tolerations when certain nodes should be reserved or protected, 
but some workloads are still allowed to run there. 
This is useful for:
    -> dedicated nodes.
    -> GPU nodes.
    -> system or infrastructure nodes.
    -> critical workloads that need special placement.

Without tolerations, the scheduler will keep Pods away from tainted nodes. 
With a matching toleration, the Pod can be placed there.

## Who uses tolerations
Platform engineers and cluster operators use them most often. 
They are also used by teams that run special workloads needing 
isolated hardware or special node pools.

## Who sets them
Tolerations are usually set in the Pod spec, Deployment spec, 
or Helm chart by the platform/app team. The corresponding taints 
are usually set on the node by cluster admins or node-pool automation.

## Example use case
Suppose you want only monitoring or system Pods to run on a node pool marked as special:

Node taint:

```console
text
key: dedicated
value: system
effect: NoSchedule
Pod toleration:

text
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "system"
  effect: "NoSchedule"
```
This means normal Pods will stay away, but Pods with this toleration may run there.

## Simple difference
    -> Sidecar = another container inside the same Pod that helps the app.
    -> Toleration = permission for a Pod to be scheduled onto a tainted node.

## Easy memory trick
    -> Sidecar is about containers inside a Pod.
    -> Toleration is about Pods on nodes.

## Practical enterprise view
Use sidecars when you need per-Pod helper behavior close to the application. 
Use tolerations when you need workload placement control across the cluster. 
They solve different layers of the system, and both are common in enterprise 
Kubernetes platforms.