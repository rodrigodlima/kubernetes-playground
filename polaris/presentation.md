---
marp: true
theme: default
paginate: true
title: Polaris - Kubernetes Configuration Validation
---

# Speaker guide: Polaris

Total time: about 17 minutes (13 slides, about 9 and a half minutes, plus 5 short demos, about 7 and a half minutes).
Short on time? Skip the demos after slides 7 and 8 (about 15 and a half minutes).

Each slide below has:

- **Show:** what is on the screen
- **Say:** a simple script you can read
- **Time:** how long to stay on the slide
- **▶ DEMO:** leave the slides, show it live, then come back to the next slide

The slides for the audience are in `Polaris Kubernetes Configuration Validation.pptx`.
The same script is in the speaker notes there, with a `▶ DEMO` line on each slide that has a demo.

## Demo map

| After slide | Where | What | Time |
|-------------|-------|------|------|
| 6. Example 1: the result | Terminal + editor | `polaris audit` on `examples/bad` (35) and `examples/good` (100) | 1:30 |
| 7. Your own rules | Editor + terminal | `customChecks` in `polaris-config.yaml`, audit gives 90 | 1:00 |
| 8. Exceptions | Editor | `exemptions` in `polaris-config.yaml` | 0:30 |
| 9. In the pipeline | Editor + Jenkins | `Jenkinsfile`, then build the 3 branches | 3:00 |
| 10. Polaris vs. native tools | Terminal | Skip Jenkins with `kubectl`: PSA blocks it, but late | 1:30 |

## Before the talk

1. Start the lab (takes a few minutes): `cd lab && ./setup.sh` (Podman: `CONTAINER_ENGINE=podman ./setup.sh`).
2. Warm up Jenkins with one build, then remove the app, so the audience sees the deploy:

   ```bash
   ./trigger.sh main
   KUBECONFIG=.work/kubeconfig-host kubectl delete deploy api -n demo
   ```

3. Open the windows, in this order (Alt+Tab between them):
   - **Slides**
   - **Editor** with `polaris/` open: `examples/bad/deployment.yaml`, `examples/good/deployment.yaml`,
     `polaris-config.yaml`, `lab/demo-app/Jenkinsfile`
   - **Terminal** in `polaris/`, with a big font and these two lines already run:

     ```bash
     export KUBECONFIG=$PWD/lab/.work/kubeconfig-host
     # Polaris from the container image, no install needed (use podman instead of docker if needed)
     alias polaris='docker run --rm -v "$PWD":/work:ro,z -w /work quay.io/fairwinds/polaris:10.1 polaris'
     ```

   - **Browser** with Jenkins logged in: <http://localhost:8080/job/polaris-demo/> (admin / admin)

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

(No demo yet: first show the result on the next slide.)

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

### ▶ DEMO: run it live (1:30) - terminal + editor

```bash
polaris audit --audit-path examples/bad --format pretty --only-show-failed-tests
polaris audit --audit-path examples/bad --format score     # 35
polaris audit --audit-path examples/good --format score    # 100
```

> Let's see it live. This is the real output, the same as the slide.

Then, in the editor, show `examples/bad/deployment.yaml` and `examples/good/deployment.yaml` side by side:

> On the right, the fixed file: securityContext, resources, probes, the image tag. That's the 100.

Back to the slides.

---

## 7. Example 2: your own rules (0:45)

**Show:** `imageRegistry` custom check in `polaris-config.yaml`

**Say:**

> You can also write your own rules, with JSON Schema.
> In this example, images must come from our registry.
> In the repo, I also have a rule for the team label.
> The perfect file had 100. With our rules, it has 90.
> Polaris does not know your company, so you add your rules.

### ▶ DEMO: custom checks (1:00) - editor + terminal

In the editor, open `polaris-config.yaml` and show `customChecks` (`imageRegistry`, `teamLabelMissing`).

```bash
polaris audit --config polaris-config.yaml --audit-path examples/good --format score     # 90
polaris audit --config polaris-config.yaml --audit-path examples/good --format pretty --only-show-failed-tests
```

> The same perfect file. With our rules: 90. The image is not from our registry, and there is no team label.

Back to the slides.

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

### ▶ DEMO: exemptions (0:30) - editor

Show the `exemptions` block at the end of `polaris-config.yaml` (kube-proxy and cilium in `kube-system`).

> It is just a few lines in the config. Anyone can review it in the PR.

Back to the slides.

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

### ▶ DEMO: the pipeline (3:00) - editor + Jenkins

1. In the editor, open `lab/demo-app/Jenkinsfile`:

   > Two stages. First the Polaris audit, with the two flags. Then the deploy. If the audit fails, there is no deploy.

2. In Jenkins: **Build with Parameters** → `main` (or in the terminal: `lab/trigger.sh main`).

   > This is a good PR. Polaris gives 100. Jenkins deploys it. Look: 3 Pods are running.

   ```bash
   kubectl get pods -n demo
   ```

3. Build `feature/insecure`.

   > Now a bad PR. The score is 12. Exit code 3. Jenkins stops, and there is no deploy.

4. Build `feature/untrusted-registry`.

   > Remember the rule from before? This one has a score of 95. Very good, right?
   > But the image comes from a registry we don't trust. One danger problem is enough. The PR is blocked.

Back to the slides.

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

### ▶ DEMO: someone skips the pipeline (1:30) - terminal

```bash
# The namespace has the PSA label
kubectl get ns demo --show-labels

# A privileged Pod: rejected right away
kubectl run insecure -n demo --image=nginx:latest --privileged

# An insecure Deployment: accepted with a WARNING, but its Pods are rejected
sed 's/^  name: api$/  name: api-bypass/; s/app: api$/app: api-bypass/' lab/demo-app/variants/insecure.yaml \
  | kubectl apply -n demo -f -
kubectl get rs -n demo -l app=api-bypass          # DESIRED 1, CURRENT 0
kubectl get events -n demo --field-selector reason=FailedCreate
```

> What if someone skips Jenkins? Pod Security Admission blocks the Pods in the cluster.
> But look: the Deployment was created, and the error is only in the events. It is late.
> This is why we use both: Polaris in the PR, and native tools in the cluster.

After the talk: `kubectl delete deploy api-bypass -n demo`

Back to the slides.

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

## After the talk

```bash
cd lab && ./teardown.sh     # Podman: CONTAINER_ENGINE=podman ./teardown.sh
```

Full lab steps and troubleshooting: `lab/README.md`.
