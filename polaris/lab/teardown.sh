#!/usr/bin/env bash
# Removes everything created by setup.sh.
set -euo pipefail
cd "$(dirname "$0")"

docker compose down -v --rmi local || true
minikube delete -p polaris-lab || true
rm -rf .work
