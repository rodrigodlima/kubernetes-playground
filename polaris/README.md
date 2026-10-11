# Polaris - Configuration Validation

Examples and slides for [Fairwinds Polaris](https://github.com/FairwindsOps/polaris), a tool that audits Kubernetes manifests against best practices (security, efficiency and reliability).

## Run with Docker

```bash
# Bad manifest - score 35, 6 danger items (exit code 3)
docker run --rm -v "$PWD:/w:ro" -w /w quay.io/fairwinds/polaris:10.1 \
  polaris audit --audit-path examples/bad --format pretty --only-show-failed-tests --set-exit-code-on-danger

# Fixed manifest - score 100
docker run --rm -v "$PWD:/w:ro" -w /w quay.io/fairwinds/polaris:10.1 \
  polaris audit --audit-path examples/good --format score

# Same manifest with company rules (custom checks) - score 90
docker run --rm -v "$PWD:/w:ro" -w /w quay.io/fairwinds/polaris:10.1 \
  polaris audit --config polaris-config.yaml --audit-path examples/good --format pretty --only-show-failed-tests
```

## Files

| File | Description |
|------|-------------|
| `presentation.md` | Speaker guide in simple English: what to show and say on each slide (~9 min) |
| `examples/bad/deployment.yaml` | Deployment with security/reliability problems |
| `examples/good/deployment.yaml` | Fixed Deployment + PodDisruptionBudget + NetworkPolicy |
| `polaris-config.yaml` | Custom severities, custom checks (`imageRegistry`, `teamLabelMissing`) and exemptions |
| `ci/github-actions-polaris.yaml` | GitHub Actions workflow that fails the PR on `danger` items or low score |

## Presenting

The audience slides are a separate Slides artifact. `presentation.md` is the speaker guide: for each slide it shows what is on the screen, a short script to say, and the time.
