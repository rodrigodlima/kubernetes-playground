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
| `presentation.md` | Slides (Marp format, ~9 min) with speaker notes |
| `examples/bad/deployment.yaml` | Deployment with security/reliability problems |
| `examples/good/deployment.yaml` | Fixed Deployment + PodDisruptionBudget + NetworkPolicy |
| `polaris-config.yaml` | Custom severities, custom checks (`imageRegistry`, `teamLabelMissing`) and exemptions |
| `ci/github-actions-polaris.yaml` | GitHub Actions workflow that fails the PR on `danger` items or low score |

## Presenting the slides

```bash
npx @marp-team/marp-cli presentation.md --html -o presentation.html   # or --pdf / --pptx
```

Or use the "Marp for VS Code" extension to preview.
