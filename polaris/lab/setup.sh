#!/usr/bin/env bash
# Creates the Polaris lab: minikube cluster + Jenkins + local demo Git repo.
# Uses its own minikube profile and kubeconfig, so ~/.kube/config is not changed.
set -euo pipefail
cd "$(dirname "$0")"

PROFILE=polaris-lab
K8S_VERSION=v1.32.0
WORK="$PWD/.work"
export KUBECONFIG="$WORK/kubeconfig-host"

mkdir -p "$WORK"

echo ">> Starting minikube (profile: $PROFILE)"
minikube start -p "$PROFILE" --driver=docker --kubernetes-version="$K8S_VERSION" --cpus=2 --memory=4096

echo ">> Creating namespace (Pod Security Admission: restricted) and PriorityClass"
kubectl apply -f cluster/

echo ">> Writing kubeconfig for Jenkins (certs embedded, API server on the minikube network)"
kubectl config view --flatten --minify > "$WORK/kubeconfig"
kubectl --kubeconfig "$WORK/kubeconfig" config set-cluster "$PROFILE" \
  --server="https://$(minikube ip -p "$PROFILE"):8443" > /dev/null
chmod 644 "$WORK/kubeconfig"   # lab only: the Jenkins container user must read it

echo ">> Creating the demo Git repo (one branch per simulated PR)"
REPO="$WORK/demo-app"
rm -rf "$REPO"
mkdir -p "$REPO"
cp -r demo-app/Jenkinsfile demo-app/polaris-config.yaml demo-app/k8s "$REPO/"
git_() { git -C "$REPO" -c user.name="Polaris Lab" -c user.email="lab@example.local" -c commit.gpgsign=false "$@"; }
git_ init -q -b main
git_ add -A && git_ commit -qm "Secure Deployment"
for variant in insecure untrusted-registry; do
  git_ checkout -qb "feature/$variant" main
  cp "demo-app/variants/$variant.yaml" "$REPO/k8s/deployment.yaml"
  git_ commit -qam "Change Deployment: $variant"
done
git_ checkout -q main
chmod -R a+rX "$REPO"

echo ">> Building and starting Jenkins"
docker compose up -d --build

echo ">> Waiting for Jenkins at http://localhost:8080"
until curl -fs -o /dev/null -u admin:admin http://localhost:8080/job/polaris-demo/api/json; do sleep 5; done

cat <<MSG

Lab is ready.
  Jenkins:  http://localhost:8080  (admin / admin)  -> job "polaris-demo"
  kubectl:  export KUBECONFIG=$WORK/kubeconfig-host
MSG
