# RBAC - ServiceAccount with Limited Role

Demonstrates Kubernetes [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/) using a `ServiceAccount` bound to a namespace-scoped `Role`. The SA can **only** read Pods in `rbac-demo` — nothing else.

## Setup

```bash
kubectl apply -f namespace.yaml
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
kubectl apply -f sample-pods.yaml
kubectl apply -f kubectl-tester.yaml

kubectl -n rbac-demo wait --for=condition=Ready pod --all --timeout=60s
```

---

## Test 1: `kubectl auth can-i` (cluster-side check)

Use the impersonation flag `--as` to ask the API server what the SA is allowed to do.

```bash
# Allowed
kubectl -n rbac-demo auth can-i list pods \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa
# yes

# Denied - SA has no create permission
kubectl -n rbac-demo auth can-i create pods \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa
# no

# Denied - SA has no access to secrets
kubectl -n rbac-demo auth can-i get secrets \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa
# no

# Denied - Role is namespace-scoped, default namespace is off-limits
kubectl -n default auth can-i list pods \
  --as=system:serviceaccount:rbac-demo:pod-reader-sa
# no
```

---

## Test 2: Run `kubectl` inside a Pod using the SA

`kubectl-tester` runs as `pod-reader-sa`. The mounted token authenticates API calls.

```bash
# Allowed - list pods in own namespace
kubectl -n rbac-demo exec kubectl-tester -- kubectl get pods
# nginx-a, nginx-b, kubectl-tester

# Denied - cross-namespace
kubectl -n rbac-demo exec kubectl-tester -- kubectl get pods -n default
# Error from server (Forbidden): pods is forbidden

# Denied - other resource in own namespace
kubectl -n rbac-demo exec kubectl-tester -- kubectl get secrets
# Error from server (Forbidden): secrets is forbidden

# Denied - mutating verb
kubectl -n rbac-demo exec kubectl-tester -- kubectl delete pod nginx-a
# Error from server (Forbidden)
```

---

## Test 3: Inspect the SA token (optional)

```bash
# Resolved permissions for the SA
kubectl -n rbac-demo describe rolebinding pod-reader-binding

# Token file mounted into the Pod
kubectl -n rbac-demo exec kubectl-tester -- \
  cat /var/run/secrets/kubernetes.io/serviceaccount/token | head -c 40
```

---

## Cleanup

```bash
kubectl delete namespace rbac-demo
```

## Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Namespace `rbac-demo` |
| `serviceaccount.yaml` | ServiceAccount `pod-reader-sa` |
| `role.yaml` | Role `pod-reader` — `get/list/watch` on Pods only |
| `rolebinding.yaml` | RoleBinding linking the SA to the Role |
| `sample-pods.yaml` | Two nginx Pods used as targets |
| `kubectl-tester.yaml` | Pod running `bitnami/kubectl` under the SA — used to test from inside the cluster |
