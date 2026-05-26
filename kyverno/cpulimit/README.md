# Kyverno - CPU Limit Validation Policy

This example demonstrates how to use [Kyverno](https://kyverno.io/) to enforce CPU limits on Kubernetes Pods.

## Policy

The `firstpolicy.yaml` defines a `ClusterPolicy` that validates whether all containers in a Pod have CPU limits defined. The policy uses `Enforce` mode, which means non-compliant Pods will be **rejected** at admission time.

```yaml
validationFailureAction: Enforce
```

If a Pod is missing CPU limits, the following message is returned:

> "The cpu limit are not defined"

## How to Use

### 1. Install Kyverno

```bash
kubectl create -f https://github.com/kyverno/kyverno/releases/latest/download/install.yaml
```

### 2. Apply the policy

```bash
kubectl apply -f firstpolicy.yaml
```

### 3. Test with a non-compliant Pod

```bash
kubectl apply -f nginx-without-cpu-limit.yaml
```

This Pod has `resources: {}` (no CPU limit), so Kyverno will **block** the deployment with the validation error message.

### 4. Test with a compliant Pod

```bash
kubectl apply -f nginx-with-cpu-limit.yaml
```

This Pod defines `resources.limits.cpu: 1`, so Kyverno will **allow** the deployment.

## Files

| File | Description |
|------|-------------|
| `firstpolicy.yaml` | ClusterPolicy that enforces CPU limits on all Pods |
| `nginx-without-cpu-limit.yaml` | Example Pod **without** CPU limits (blocked by policy) |
| `nginx-with-cpu-limit.yaml` | Example Pod **with** CPU limits (allowed by policy) |
