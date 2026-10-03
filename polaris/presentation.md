---
marp: true
theme: default
paginate: true
title: Polaris - Kubernetes Configuration Validation
---

# Speaker guide: Polaris

Total time: about 9 and a half minutes (13 slides).

Each slide below has:

- **Show:** what is on the screen
- **Say:** a simple script you can read
- **Time:** how long to stay on the slide

The slides for the audience are in the Slides artifact. The same script is in the speaker notes there.

---

## 1. Cover (0:20)

**Show:** "Find bad Kubernetes YAML before the merge"

**Say:**

> Hello! Today I will talk about Polaris. Polaris checks Kubernetes YAML files.
> First, a question: who here approved a PR with a YAML file that worked, but was not good?

---

## 2. The problem (0:45)

**Show:** YAML with `image: nginx:latest` and `privileged: true`

**Say:**

> Look at this YAML. kubectl says yes. The Pod starts.
> But the image tag is `latest`, and the container runs as root.
> The API server only checks the format. It does not check good practices.
> Later, we see the problems: security problems, Pods killed because of memory, lost traffic.
> A late problem is an expensive problem. So we want to find it early, in the PR.

---

## 3. What is Polaris (0:45)

**Show:** three cards: CLI, Admission webhook, Dashboard

**Say:**

> Polaris is an open source tool from Fairwinds.
> It is in the CNCF Landscape, but it is not a CNCF project.
> You can use it in three ways: in CI, as a webhook in the cluster, or as a dashboard.
> You use the same config file for all three. Today I will talk about the CLI.

**If someone asks:** `polaris fix` can fix some problems in the YAML for you.

---

## 4. How checks are organized (0:45)

**Show:** Security, Efficiency, Reliability · ignore, warning, danger · score 0–100

**Say:**

> Polaris has three groups of checks: security, efficiency and reliability.
> Each check has a level: ignore, warning or danger.
> Polaris also gives you a score, from 0 to 100.
> This is great for old projects. You don't need to fix everything on day one.

---

## 5. Example 1: a "first commit" Deployment (0:30)

**Show:** `examples/bad/deployment.yaml`

**Say:**

> This is a normal Deployment. Maybe it is your first commit.
> Look at it for a few seconds. How many problems can you see?
> Let's ask Polaris.

**Command:**

```bash
polaris audit --audit-path examples/bad --format pretty --only-show-failed-tests
```

---

## 6. Example 1: the result (1:00)

**Show:** score 35 → 100, table with the 6 danger checks

**Say:**

> This is the real output from Polaris. The score is 35.
> There are 24 problems, and 6 are danger.
> Kubernetes does not block any of them.
> Then I fixed the file. I added securityContext, resources, probes, an image tag,
> 3 replicas, a PDB and a NetworkPolicy. Now the score is 100.

**The 6 danger checks:** `hostNetworkSet`, `runAsPrivileged`, `runAsRootAllowed`,
`privilegeEscalationAllowed`, `dangerousCapabilities`, `tagNotSpecified`.

---

## 7. Example 2: your own rules (0:45)

**Show:** `imageRegistry` custom check in `polaris-config.yaml`

**Say:**

> You can also write your own rules, with JSON Schema.
> In this example, images must come from our registry.
> In the repo, I also have a rule for the team label.
> The perfect file had 100. With our rules, it has 90.
> Polaris does not know your company, so you add your rules.

---

## 8. Example 3: exceptions (0:30)

**Show:** `exemptions` in the config, and the annotation in the YAML

```yaml
metadata:
  annotations:
    polaris.fairwinds.com/hostNetworkSet-exempt: "true"
```

**Say:**

> Some apps must break a rule. For example, kube-proxy and the CNI need hostNetwork.
> You can add an exception in the config file, or in the YAML file with an annotation.
> The good part: everyone can see the exception in the PR.

---

## 9. In the pipeline (0:45)

**Show:** Jenkinsfile, exit codes 3 and 4

**Say:**

> Now let's put Polaris in the pipeline. We use Jenkins.
> With these two flags, Polaris returns an exit code.
> Exit code 3 means a danger problem. Exit code 4 means the score is too low.
> When the exit code is not zero, Jenkins stops. There is no deploy.
> My tip: start with warnings and a low score. Then go up a little every sprint.

| Flag | Exit code |
|------|-----------|
| `--set-exit-code-on-danger` | 3 |
| `--set-exit-code-below-score N` | 4 |

File in the repo: `lab/demo-app/Jenkinsfile`

------|-----------|
| `--set-exit-code-on-danger` | 3 |
| `--set-exit-code-below-score N` | 4 |

File in the repo: `ci/github-actions-polaris.yaml`

---

## 10. Polaris vs. native tools (1:15)

**Show:** table: Polaris CLI, Pod Security Admission, ValidatingAdmissionPolicy, dry-run / kubeconform

**Say:**

> Now, Polaris or native tools?
> Kubernetes has Pod Security Admission. You add a label to the namespace, for example `restricted`.
> It is simple, but it only checks Pod security.
> Kubernetes also has ValidatingAdmissionPolicy, with CEL.
> It is very powerful, but you must write all the rules.
> Both run in the cluster, so you see the error late, on apply.
> Polaris runs before, in the PR.

**If someone asks:**

- PSA label: `pod-security.kubernetes.io/enforce: restricted`
- ValidatingAdmissionPolicy is GA since Kubernetes 1.30
- LimitRange and ResourceQuota are native too, but they set defaults and limits. They don't check good practices.
- Kyverno and OPA Gatekeeper: more powerful than Polaris, but harder to run.

---

## 11. Pros and cons (1:00)

**Show:** two cards, Pros and Cons

**Say:**

> First, the good part. Polaris is easy. You get value on day one,
> and it runs in the PR, with no cluster.
> Now, the bad part. At first you see many warnings, so you must change the config.
> JSON Schema is simple, so complex rules are hard.
> And people can skip CI with kubectl apply.
> So you still need checks in the cluster.

**If someone asks:** noisy default checks are `pullPolicyNotAlways`, `priorityClassNotSet`
and `topologySpreadConstraint`. The webhook's `failurePolicy` decides what happens when it is down.

---

## 12. Recommendation: use layers (0:45)

**Show:** PR / CI → Admission → Runtime

**Say:**

> My recommendation: use layers.
> Polaris in CI teaches the team, early.
> Pod Security Admission and ValidatingAdmissionPolicy in the cluster block bad YAML.
> The Polaris dashboard watches apps that are already running.
> Polaris does not replace native tools.
> It helps you find problems in the PR, not in production.

---

## 13. Thank you (0:20)

**Say:**

> Thank you! Any questions?

**Links:**

- https://polaris.docs.fairwinds.com
- https://github.com/FairwindsOps/polaris
- https://www.cncf.io/blog/2021/07/01/what-is-fairwinds-polaris-kubernetes-open-source-configuration-validation/
- https://kubernetes.io/docs/concepts/security/pod-security-admission/
- https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/

---

## Live demo (optional, +3 min)

Run `cd lab && ./setup.sh` **before** the talk. Open Jenkins at http://localhost:8080 (admin / admin).
Do the demo after slide 9. Full steps: `lab/README.md`.

1. **Build `main`**

   > This is a good PR. Polaris gives 100. Jenkins deploys it. Look: 3 Pods are running.

2. **Build `feature/insecure`**

   > Now a bad PR. The score is 12. Exit code 3. Jenkins stops, and there is no deploy.

3. **Build `feature/untrusted-registry`**

   > This one has a score of 95. Very good, right? But the image comes from a registry we don't trust.
   > One danger problem is enough. The PR is blocked.

4. **Skip CI with `kubectl apply`**

   > What if someone skips Jenkins? Pod Security Admission blocks the Pods in the cluster.
   > But look: the Deployment was created, and the error is only in the events. It is late.
   > This is why we use both: Polaris in the PR, and native tools in the cluster.

