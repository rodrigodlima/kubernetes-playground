# PodDisruptionBudget

Demonstrates Kubernetes [PodDisruptionBudget](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) — a policy that limits how many pods can be voluntarily disrupted at once (node drain, rolling update, cluster upgrade).

Two variants are provided:
- `pdb-min-available.yaml` — at least **2 pods** must remain running at all times
- `pdb-max-unavailable.yaml` — at most **1 pod** can be unavailable at any time

Both express the same intent for a 3-replica deployment. Choose one to apply.

## Setup

```bash
kubectl apply -f namespace.yaml
kubectl apply -f deployment.yaml

# Pick one:
kubectl apply -f pdb-min-available.yaml
# OR
kubectl apply -f pdb-max-unavailable.yaml

kubectl -n pdb-demo wait --for=condition=Available deployment/web --timeout=60s
```

---

## Test 1: Inspect PDB status

```bash
kubectl -n pdb-demo get pdb
```

Expected output:
```
NAME      MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
web-pdb   2               N/A               1                     10s
```

`ALLOWED DISRUPTIONS: 1` means the scheduler can safely evict 1 pod right now (3 running − 2 required = 1 budget).

---

## Test 2: Force eviction via API (simulates what `kubectl drain` does)

```bash
# Get any pod name
POD=$(kubectl -n pdb-demo get pods -o jsonpath='{.items[0].metadata.name}')

# Evict it — this goes through the PDB
kubectl -n pdb-demo delete pod $POD
```

Pod is deleted because budget allows 1 disruption. Deployment immediately reschedules a replacement.

---

## Test 3: Budget exhausted — eviction blocked

Scale down to 2 replicas so no disruption budget remains, then try to evict:

```bash
kubectl -n pdb-demo scale deployment web --replicas=2

# Budget: 2 running − 2 minAvailable = 0 allowed disruptions
kubectl -n pdb-demo get pdb
# ALLOWED DISRUPTIONS: 0

# Try to evict a pod using the eviction API
POD=$(kubectl -n pdb-demo get pods -o jsonpath='{.items[0].metadata.name}')
kubectl -n pdb-demo delete pod $POD
```

With `kubectl delete` the pod is still deleted (delete bypasses the eviction API). To observe blocking behavior, use the eviction endpoint directly:

```bash
POD=$(kubectl -n pdb-demo get pods -o jsonpath='{.items[0].metadata.name}')

kubectl proxy &

curl -s -X POST "http://localhost:8001/api/v1/namespaces/pdb-demo/pods/${POD}/eviction" \
  -H "Content-Type: application/json" \
  -d '{
    "apiVersion": "policy/v1",
    "kind": "Eviction",
    "metadata": {
      "name": "'"$POD"'",
      "namespace": "pdb-demo"
    }
  }'
```

Expected response:
```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "status": "Failure",
  "message": "Cannot evict pod as it would violate the pod's disruption budget.",
  "reason": "TooManyRequests",
  "code": 429
}
```

Restore replicas and kill the proxy:

```bash
kubectl -n pdb-demo scale deployment web --replicas=3
kill %1
```

---

## Test 4: Node drain respects PDB

On a multi-node cluster, drain a node and observe the PDB gate the evictions:

```bash
NODE=$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')

kubectl drain $NODE --ignore-daemonsets --delete-emptydir-data
```

The drain will evict pods one at a time, waiting for replacements to become Ready before proceeding — PDB ensures availability is maintained throughout.

Uncordon when done:

```bash
kubectl uncordon $NODE
```

---

## Cleanup

```bash
kubectl delete namespace pdb-demo
```

---

## Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Namespace `pdb-demo` |
| `deployment.yaml` | Deployment `web` — 3 replicas of nginx |
| `pdb-min-available.yaml` | PDB using `minAvailable: 2` |
| `pdb-max-unavailable.yaml` | PDB using `maxUnavailable: 1` (same effect, different expression) |
