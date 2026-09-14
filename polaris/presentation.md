---
marp: true
theme: default
paginate: true
title: Polaris - Kubernetes Configuration Validation
---

<!-- _class: lead -->

# Polaris 🧭

### Validating Kubernetes configuration *before* the merge

Rodrigo de Lima Silva

<!--
Target total time: ~9min30 (13 slides). (0:20)
Open with a question: "how many of you have approved a PR with a YAML that 'worked'?"
-->

---

## The problem: "it works" ≠ "it's good"

```yaml
containers:
  - name: api
    image: nginx:latest          # which version will run tomorrow?
    securityContext:
      privileged: true           # root on the node
```

- `kubectl apply` accepts it. The Pod starts. Human review doesn't catch everything.
- The problems show up later: **security incident**, **OOMKill**, **noisy neighbor**, **deploy without probes dropping traffic**.
- The later a mistake is found, the more expensive it is → **shift-left**.

<!--
(0:45) Emphasis: the API server only validates SCHEMA, not best practices.
-->

---

## What is Polaris

Open source tool by **Fairwinds** that audits Kubernetes workloads against best practices.

| Mode | Where it runs | What for |
|------|---------------|----------|
| **CLI** (`polaris audit`) | CI/CD, local machine | Validate YAML / Helm **before** deploy |
| **Admission Controller** (`webhook`) | Inside the cluster | Block what didn't go through the pipeline |
| **Dashboard** | Inside the cluster | View of what is **already** running |

- ~30 built-in checks, zero configuration to get started
- Same config file across all 3 modes
- Bonus: `polaris fix` automatically fixes some issues

<!--
(0:45) It is part of the CNCF Landscape and has a post on the CNCF blog,
but it is maintained by Fairwinds (not a CNCF hosted/incubating project).
Today's focus is the CLI mode.
-->

---

## How checks are organized

**3 categories**

- 🔒 **Security** — `runAsPrivileged`, `runAsRootAllowed`, `hostNetworkSet`, `dangerousCapabilities`, `privilegeEscalationAllowed`, `notReadOnlyRootFilesystem`
- ⚡ **Efficiency** — `cpuRequestsMissing`, `memoryLimitsMissing`, …
- 🛟 **Reliability** — `readinessProbeMissing`, `livenessProbeMissing`, `tagNotSpecified`, `deploymentMissingReplicas`, `missingPodDisruptionBudget`

**3 severities** — `ignore` · `warning` 😬 · `danger` ❌

**Score from 0 to 100** → enables gradual adoption (e.g. "no repo below 80")

<!--
(0:45) The score is the differentiator for teams with legacy: no need to fix everything on day 1.
-->

---

## Example 1 — a "first commit" Deployment

```yaml
spec:
  replicas: 1
  template:
    spec:
      hostNetwork: true
      containers:
        - name: api
          image: nginx:latest
          securityContext:
            privileged: true
            allowPrivilegeEscalation: true
            capabilities:
              add: ["NET_ADMIN", "SYS_ADMIN"]
```

```bash
polaris audit --audit-path examples/bad --format pretty --only-show-failed-tests
```

<!--
(0:30) Full file: examples/bad/deployment.yaml
-->

---

## Example 1 — the result

```text
Polaris audited Path examples/bad
    Nodes: 0 | Namespaces: 0 | Controllers: 1
    Final score: 35

Deployment api in namespace demo
    hostNetworkSet               ❌ Danger   Security - Host network should not be configured
    deploymentMissingReplicas    😬 Warning  Reliability - Only one replica is scheduled
    missingPodDisruptionBudget   😬 Warning  Reliability - Should have a PodDisruptionBudget
  Container api
    runAsPrivileged              ❌ Danger   Security - Should not be running as privileged
    runAsRootAllowed             ❌ Danger   Security - Should not be allowed to run as root
    privilegeEscalationAllowed   ❌ Danger   Security - Privilege escalation should not be allowed
    dangerousCapabilities        ❌ Danger   Security - Container should not have dangerous capabilities
    tagNotSpecified              ❌ Danger   Reliability - Image tag should be specified
    cpuRequestsMissing           😬 Warning  Efficiency - CPU requests should be set
    memoryLimitsMissing          😬 Warning  Efficiency - Memory limits should be set
    readinessProbeMissing        😬 Warning  Reliability - Readiness probe should be configured
    ... (24 findings in total)
```

**Score 35, 6 `danger` items.** Fixed (`examples/good/`) → **score 100**.

<!--
(1:00) Real output (Polaris 10.1). Highlight: ~15 lines of YAML, 24 findings, none of them
would be blocked by the API server. The fixed version adds securityContext, resources,
probes, pinned tag, 3 replicas, PDB and NetworkPolicy.
-->

---

## Example 2 — *your* company's rules (custom checks)

Custom checks are written in **JSON Schema**:

```yaml
checks:
  imageRegistry: danger
customChecks:
  imageRegistry:
    category: Security
    target: Container
    failureMessage: Image must come from ghcr.io/my-org or registry.k8s.io
    schema:
      '$schema': http://json-schema.org/draft-07/schema
      type: object
      properties:
        image:
          type: string
          anyOf:
            - pattern: ^ghcr.io/my-org/.+$
            - pattern: ^registry.k8s.io/.+$
```

Other useful examples: required `team` label, forbid `NodePort`, require `resources` on `initContainers`, cap maximum `replicas`.

<!--
(0:45) In the repo, polaris-config.yaml has imageRegistry + teamLabelMissing.
The "perfect" manifest (score 100) drops to 90 with company rules — the defaults don't know your context.
-->

---

## Example 3 — explicit, auditable exemptions

Not every rule applies to everything (e.g. CNI and kube-proxy **need** `hostNetwork`).

**In the central config:**

```yaml
exemptions:
  - namespace: kube-system
    controllerNames: ["kube-proxy", "cilium"]
    rules: ["hostNetworkSet", "runAsPrivileged"]
```

**In the manifest itself** (visible in the PR):

```yaml
metadata:
  annotations:
    polaris.fairwinds.com/hostNetworkSet-exempt: "true"
```

<!--
(0:30) The exemption becomes something reviewable in code review, instead of "just turn off the check".
-->

---

## In the pipeline: blocking the PR

```yaml
# .github/workflows/polaris.yaml
on: pull_request
jobs:
  polaris:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: |
          docker run --rm -v "$PWD:/repo:ro" -w /repo quay.io/fairwinds/polaris:10.1 \
            polaris audit --config polaris-config.yaml --audit-path k8s/ \
              --format pretty \
              --set-exit-code-on-danger \
              --set-exit-code-below-score 80
```

| Flag | Exit code |
|------|-----------|
| `--set-exit-code-on-danger` | **3** if there is any `danger` |
| `--set-exit-code-below-score N` | **4** if score < N |

Helm: `--helm-chart charts/api --helm-values values-prod.yaml` renders and audits.

<!--
(0:45) Mark the job as a required check in branch protection → the PR can't be merged.
Rollout strategy: start with warnings / low score threshold, raise it every sprint.
-->

---

## Polaris vs. native Kubernetes tools

| | Polaris (CLI) | Pod Security Admission | ValidatingAdmissionPolicy (CEL) | `kubectl --dry-run=server` / kubeconform |
|---|---|---|---|---|
| Where it validates | **CI, offline** | Cluster (admission) | Cluster (admission) | CI / cluster |
| Scope | Security + Efficiency + Reliability | Pod security only | Whatever you write | API schema only |
| Built-in rules | ~30 checks | 3 fixed profiles (privileged / baseline / restricted) | None | — |
| Customization | JSON Schema | None | CEL (very flexible) | — |
| Extra component | No (in CI) | No, it's native | No, it's native (GA 1.30) | No |
| Developer feedback | In the PR, with score | On `apply` (late) | On `apply` (late) | In the PR |

> Native = guaranteed and dependency-free, but **happens late** and either covers only security or requires you to write everything.
> Kyverno / OPA Gatekeeper sit in between: more powerful than Polaris, more complex to operate.

<!--
(1:15) LimitRange/ResourceQuota are also native, but they set defaults/caps — they don't validate best practices.
PSA: namespace label, e.g. pod-security.kubernetes.io/enforce: restricted.
-->

---

## Tradeoffs

**✅ Pros**

- Value on day 1: built-in checks, no policy writing
- **Real shift-left**: runs without a cluster, feedback in the PR
- Score enables **gradual** adoption for teams with legacy
- Covers efficiency and reliability, not just security
- Same config in CI, webhook and dashboard

**⚠️ Cons**

- **Opinionated**: defaults generate noise (`pullPolicyNotAlways`, `priorityClassNotSet`, `topologySpreadConstraint`) → needs tuning
- JSON Schema is **less expressive** than CEL/Rego (limited conditional and cross-resource logic)
- Static analysis **can't see** what mutating webhooks, defaults and runtime values do
- A CI check can be **bypassed** (direct `kubectl apply`) → admission is needed too
- Webhook in the cluster = one more component in the critical path (`failurePolicy`)
- Vendor-maintained project, smaller community than Kyverno/OPA

<!--
(1:00)
-->

---

## Recommendation: defense in depth

```text
  PR / CI                     Admission (cluster)               Runtime
┌──────────────┐          ┌──────────────────────────┐      ┌──────────────┐
│   Polaris    │  merge → │ Pod Security Admission   │  →   │  Polaris     │
│   audit      │          │   (restricted)           │      │  Dashboard   │
│ fast feedback│          │ + ValidatingAdmission-   │      │  drift /     │
│   + score    │          │   Policy / Kyverno       │      │  legacy      │
└──────────────┘          └──────────────────────────┘      └──────────────┘
   "educates"                  "enforces"                     "observes"
```

- **Polaris in CI** for fast feedback and broad best practices
- **Native in the cluster** (PSA + VAP) as a safety net that doesn't depend on the pipeline
- Start with `warning`, measure the score, **tighten gradually**

<!--
(0:45) Closing message: Polaris doesn't replace native admission — it makes developers find the problem
in the PR, instead of on apply or during an incident.
-->

---

<!-- _class: lead -->

# Thank you! 🙋

**Demo in the repo:** `kubernetes-playground/polaris`

- `examples/bad` → score 35 · `examples/good` → score 100
- `polaris-config.yaml` → custom checks + exemptions
- `ci/github-actions-polaris.yaml` → pipeline

**References**

- https://polaris.docs.fairwinds.com
- https://github.com/FairwindsOps/polaris
- https://www.cncf.io/blog/2021/07/01/what-is-fairwinds-polaris-kubernetes-open-source-configuration-validation/
- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/

<!--
(0:20) Open for questions.
-->
