# Polaris Lab - minikube + Jenkins

A local lab to show Polaris in a real pipeline:

- **minikube** cluster (own profile `polaris-lab`, own kubeconfig - your `~/.kube/config` is not changed)
- **Jenkins** in a container (Docker or Podman), configured as code (JCasC), with `polaris` and `kubectl` installed
- A local **Git repo** with one branch per simulated PR
- Namespace `demo` with **Pod Security Admission** `restricted` (the native layer)

```text
 demo-app (git)          Jenkins (container)                   minikube
┌────────────────┐     ┌─────────────────────────────┐     ┌──────────────────────┐
│ main           │ ──► │ 1. Polaris audit            │     │ namespace demo       │
│ feature/...    │     │    exit 3 / 4 → stop        │     │ PSA: restricted      │
└────────────────┘     │ 2. kubectl apply + rollout  │ ──► │ Deployment api       │
                       └─────────────────────────────┘     └──────────────────────┘
```

## Prerequisites

- Docker (with Docker Compose) **or** Podman (with `podman compose` or `podman-compose`)
- minikube (tested with v1.35)
- kubectl
- About 4 GB RAM free and internet access (images are pulled on first run)

## Setup

```bash
./setup.sh
```

`setup.sh` uses Docker when it is installed, otherwise Podman. To choose:

```bash
CONTAINER_ENGINE=podman ./setup.sh     # same variable for ./teardown.sh
```

It takes a few minutes the first time. At the end:

- Jenkins: <http://localhost:8080> (user `admin`, password `admin`) → job **polaris-demo**
- kubectl: `export KUBECONFIG=$PWD/.work/kubeconfig-host`

## Demo script

Run each build from the Jenkins UI (**Build with Parameters** → choose `BRANCH`) or from the terminal:

| Step | Command | What happens |
|------|---------|--------------|
| 1. Good PR | `./trigger.sh main` | Score **100** → deployed, 3 Pods running |
| 2. Insecure PR | `./trigger.sh feature/insecure` | Score **12**, 9 danger → **exit code 3**, deploy skipped |
| 3. Company rule | `./trigger.sh feature/untrusted-registry` | Score **95**, but `imageRegistry` is danger → blocked |
| 4. Skip CI | see below | Pod Security Admission blocks it in the cluster |

Step 3 shows that a good score is not enough: one `danger` finding blocks the PR.

### Step 4 - someone skips the pipeline

```bash
export KUBECONFIG=$PWD/.work/kubeconfig-host

# A privileged Pod: rejected right away
kubectl run insecure -n demo --image=nginx:latest --privileged

# An insecure Deployment: accepted with a WARNING, but its Pods are rejected
sed 's/^  name: api$/  name: api-bypass/; s/app: api$/app: api-bypass/' demo-app/variants/insecure.yaml \
  | kubectl apply -n demo -f -
kubectl get rs -n demo -l app=api-bypass          # DESIRED 1, CURRENT 0
kubectl get events -n demo --field-selector reason=FailedCreate

# Clean up
kubectl delete deploy api-bypass -n demo
```

Message for the audience: the native layer protects the cluster, but the feedback is **late** -
the Deployment is created and the error is only in the events. Polaris shows it **in the PR**.

## Files

| File | Description |
|------|-------------|
| `setup.sh` / `teardown.sh` | Create / delete the whole lab |
| `engine.sh` | Picks Docker or Podman (minikube driver + compose command) |
| `trigger.sh` | Start a build for a branch, wait, print the console output |
| `docker-compose.yaml` | Jenkins container (Docker or Podman), joined to the `polaris-lab` minikube network |
| `jenkins/Dockerfile` | Jenkins LTS + `polaris` (copied from the official image) + `kubectl` |
| `jenkins/casc.yaml` | Jenkins config as code: admin user and the `polaris-demo` pipeline job |
| `jenkins/plugins.txt` | Jenkins plugins |
| `demo-app/Jenkinsfile` | Pipeline: Polaris audit (quality gate) → deploy to minikube |
| `demo-app/polaris-config.yaml` | Severities and custom checks (`imageRegistry`, `teamLabelMissing`) |
| `demo-app/k8s/deployment.yaml` | Secure Deployment + PDB + NetworkPolicy (branch `main`) |
| `demo-app/variants/*.yaml` | Deployment used by each `feature/*` branch |
| `cluster/namespace.yaml` | Namespace `demo` (PSA `restricted`) and the `app-default` PriorityClass |

`setup.sh` builds the Git repo in `.work/demo-app` from `demo-app/`: `main` uses `k8s/`,
and each `feature/<name>` branch replaces `k8s/deployment.yaml` with `variants/<name>.yaml`.
To change a scenario, edit the files in `demo-app/` and run `./setup.sh` again.

## Teardown

```bash
./teardown.sh
```

## Podman

With Podman, `setup.sh` runs `minikube start --driver=podman --container-runtime=containerd`
and starts Jenkins with `podman compose` (or `podman-compose`).

- **Rootless Podman** (the default) is expected: minikube and Jenkins must be in the same
  Podman, so Jenkins can join the `polaris-lab` network. `engine.sh` sets `MINIKUBE_ROOTLESS=true`.
- Rootless minikube needs cgroup v2 with CPU delegation. If `minikube start` fails, see
  <https://minikube.sigs.k8s.io/docs/drivers/podman/> and
  <https://rootlesscontaine.rs/getting-started/common/cgroup2/>.
- The `docker` command from the `podman-docker` package is detected as Podman.
- If minikube still has an old profile from another driver: `minikube delete -p polaris-lab`.

## Notes

- Local lab only: Jenkins uses `admin/admin` and a cluster-admin kubeconfig (`.work/kubeconfig`).
- Jenkins checks out the repo with `file:///demo-app`, so it needs
  `-Dhudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT=true` (set in the Dockerfile).
  In a real setup, Jenkins reads from your Git server and runs the job on each PR.
- In `jenkins/casc.yaml`, `^${BRANCH}` is escaped on purpose: JCasC would replace `${BRANCH}` with an empty value.
