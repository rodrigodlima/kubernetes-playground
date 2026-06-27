# Kustomize vs Helm

Both tools solve the same problem: managing Kubernetes manifests across multiple environments. The approach each one takes is very different.

This POC deploys a simple nginx app to `dev` and `prod` environments using each tool, so you can see the difference hands-on.

---

## Kustomize

Kustomize works with plain YAML. There are no templates, no functions, no new syntax to learn. You write real Kubernetes manifests and use patches to override specific fields per environment.

**Structure:**
```
kustomize/
  base/               # base manifests shared by all environments
  overlays/
    dev/              # patches applied on top of base for dev
    prod/             # patches applied on top of base for prod
```

The `base/` folder has the deployment and service as-is. Each overlay has a `kustomization.yaml` that points to the base and lists its patches.

### Commands

Preview the rendered output (dry-run):
```bash
kubectl kustomize kustomize/overlays/dev
kubectl kustomize kustomize/overlays/prod
```

Apply to the cluster:
```bash
kubectl apply -k kustomize/overlays/dev
kubectl apply -k kustomize/overlays/prod
```

Delete:
```bash
kubectl delete -k kustomize/overlays/dev
kubectl delete -k kustomize/overlays/prod
```

---

## Helm

Helm works with templates. Manifests are Go templates where values are injected at install time. You define defaults in `values.yaml` and override them with environment-specific files.

**Structure:**
```
helm/
  app-chart/
    Chart.yaml          # chart metadata
    values.yaml         # default values
    values-dev.yaml     # dev overrides
    values-prod.yaml    # prod overrides
    templates/          # Go-templated Kubernetes manifests
```

### Commands

Preview the rendered output (dry-run):
```bash
helm template dev-release helm/app-chart -f helm/app-chart/values-dev.yaml --namespace dev
helm template prod-release helm/app-chart -f helm/app-chart/values-prod.yaml --namespace prod
```

Install:
```bash
helm install dev-release helm/app-chart -f helm/app-chart/values-dev.yaml --namespace dev --create-namespace
helm install prod-release helm/app-chart -f helm/app-chart/values-prod.yaml --namespace prod --create-namespace
```

Upgrade after changes:
```bash
helm upgrade dev-release helm/app-chart -f helm/app-chart/values-dev.yaml --namespace dev
```

Uninstall:
```bash
helm uninstall dev-release --namespace dev
helm uninstall prod-release --namespace prod
```

---

## Key Differences

| | Kustomize | Helm |
|---|---|---|
| Syntax | Plain YAML + patches | Go templates |
| Learning curve | Low | Medium |
| Release management | None (kubectl handles it) | Built-in (history, rollback) |
| Logic in templates | No | Yes (conditionals, loops) |
| External charts | No | Yes (dependencies) |
| Built into kubectl | Yes (`kubectl apply -k`) | No (separate binary) |

Kustomize is a better fit when you want to keep manifests readable and close to plain Kubernetes YAML. Helm is a better fit when you need packaging, versioning, or distributing charts for others to use.
