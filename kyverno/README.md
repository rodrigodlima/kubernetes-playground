# Kyverno - Policy Examples

This repository contains examples of [Kyverno](https://kyverno.io/) policies for Kubernetes admission control.

## Install Kyverno

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml
```

---

## 1. CPU Limit Validation (`cpulimit/`)

A `ClusterPolicy` that enforces CPU limits on all Pod containers. Uses `Enforce` mode, so non-compliant Pods are **rejected** at admission time.

If a Pod is missing CPU limits, the following message is returned:

> "The cpu limit are not defined"

### How to test

```bash
# Apply the policy
kubectl apply -f cpulimit/firstpolicy.yaml

# Blocked - no CPU limit defined
kubectl apply -f cpulimit/nginx-without-cpu-limit.yaml

# Allowed - CPU limit defined
kubectl apply -f cpulimit/nginx-with-cpu-limit.yaml
```

### Files

| File | Description |
|------|-------------|
| `cpulimit/firstpolicy.yaml` | ClusterPolicy that enforces CPU limits on all Pods |
| `cpulimit/nginx-without-cpu-limit.yaml` | Example Pod **without** CPU limits (blocked) |
| `cpulimit/nginx-with-cpu-limit.yaml` | Example Pod **with** CPU limits (allowed) |

---

## 2. Require Labels (`requiteLabels/`)

A `ValidatingPolicy` that requires Pods to have `app` and `version` labels. Uses the Kyverno CEL-based policy format (`policies.kyverno.io/v1`) and validates on `CREATE` and `UPDATE` operations.

If a Pod is missing the required labels, the following message is returned:

> "Pods must have 'app' and 'version' labels"

### How to test

```bash
# Apply the policy
kubectl apply -f requiteLabels/require-labels.yaml

# Blocked - missing 'app' and 'version' labels
kubectl run nginx --image=nginx

# Allowed - both labels present
kubectl run nginx --image=nginx --labels="app=nginx,version=v1"
```

### Files

| File | Description |
|------|-------------|
| `requiteLabels/require-labels.yaml` | ValidatingPolicy that requires `app` and `version` labels on Pods |

---

## 3. Enforce Non-Root Containers (`enforceNonRootContainer/`)

A `ClusterPolicy` that prevents containers from running as root. Uses `Enforce` mode, so Pods without `runAsNonRoot: true` in their security context are **rejected** at admission time.

If a Pod is missing the required security context, the following message is returned:

> "Running as root is not allowed. Set runAsNonRoot to true."

### How to test

```bash
# Apply the policy
kubectl apply -f enforceNonRootContainer/enforce-nonroot.yaml

# Blocked - no runAsNonRoot set
kubectl apply -f enforceNonRootContainer/nginx-root.yaml

# Allowed - runAsNonRoot set to true
kubectl run nginx --image=nginx --overrides='{"spec":{"containers":[{"name":"nginx","image":"nginx","securityContext":{"runAsNonRoot":true}}]}}'
```

### Files

| File | Description |
|------|-------------|
| `enforceNonRootContainer/enforce-nonroot.yaml` | ClusterPolicy that enforces `runAsNonRoot: true` on all Pod containers |
| `enforceNonRootContainer/nginx-root.yaml` | Example Pod **without** `runAsNonRoot` (blocked) |
