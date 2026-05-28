# NetworkPolicy - Traffic Isolation Demo

Demonstrates Kubernetes [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to control Pod-to-Pod traffic.

> **Prerequisite:** Your cluster must use a CNI plugin that supports NetworkPolicy (e.g., Calico, Cilium, Weave). Minikube with `--cni=calico` works. The default kubenet CNI does **not** enforce NetworkPolicy.

## Setup

```bash
# Create the namespace and deploy pods + service
kubectl apply -f namespace.yaml
kubectl apply -f nginx.yaml
kubectl apply -f curl-allowed.yaml
kubectl apply -f curl-blocked.yaml

# Wait for all pods to be ready
kubectl -n netpol-demo wait --for=condition=Ready pod --all --timeout=60s
```

---

## Test 1: No policy (all traffic allowed)

Both curl pods can reach nginx:

```bash
# From curl-allowed (role=frontend)
kubectl -n netpol-demo exec curl-allowed -- curl -s --max-time 3 http://nginx
# ✅ Returns nginx HTML

# From curl-blocked (role=monitoring)
kubectl -n netpol-demo exec curl-blocked -- curl -s --max-time 3 http://nginx
# ✅ Returns nginx HTML
```

---

## Test 2: Deny all ingress

Block **all** incoming traffic to nginx:

```bash
kubectl apply -f deny-all-ingress.yaml

# From curl-allowed
kubectl -n netpol-demo exec curl-allowed -- curl -s --max-time 3 http://nginx
# ❌ Timeout - blocked

# From curl-blocked
kubectl -n netpol-demo exec curl-blocked -- curl -s --max-time 3 http://nginx
# ❌ Timeout - blocked
```

---

## Test 3: Allow only frontend pods

Replace the deny-all policy with one that allows only `role=frontend` pods:

```bash
kubectl delete -f deny-all-ingress.yaml
kubectl apply -f allow-frontend-only.yaml

# From curl-allowed (role=frontend)
kubectl -n netpol-demo exec curl-allowed -- curl -s --max-time 3 http://nginx
# ✅ Returns nginx HTML

# From curl-blocked (role=monitoring)
kubectl -n netpol-demo exec curl-blocked -- curl -s --max-time 3 http://nginx
# ❌ Timeout - blocked
```

---

## Cleanup

```bash
kubectl delete namespace netpol-demo
```

## Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Namespace `netpol-demo` |
| `nginx.yaml` | Nginx Pod + Service (target) |
| `curl-allowed.yaml` | Curl Pod with `role=frontend` label (allowed by policy) |
| `curl-blocked.yaml` | Curl Pod with `role=monitoring` label (blocked by policy) |
| `deny-all-ingress.yaml` | NetworkPolicy that blocks **all** ingress to nginx |
| `allow-frontend-only.yaml` | NetworkPolicy that allows ingress **only** from `role=frontend` pods |
