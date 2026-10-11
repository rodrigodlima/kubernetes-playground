#!/usr/bin/env bash
# Removes everything created by setup.sh.
set -euo pipefail
cd "$(dirname "$0")"

source ./engine.sh

"${COMPOSE[@]}" down -v || true
"$CONTAINER_ENGINE" rmi polaris-lab-jenkins:local 2> /dev/null || true
minikube delete -p polaris-lab || true
rm -rf .work
