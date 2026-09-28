#!/usr/bin/env bash
# Triggers the polaris-demo job for a branch (simulated PR), waits, and prints the console output.
# Usage: ./trigger.sh [main|feature/insecure|feature/untrusted-registry]
set -euo pipefail

BRANCH="${1:-main}"
JENKINS=http://localhost:8080
AUTH=admin:admin
COOKIES=$(mktemp)
trap 'rm -f "$COOKIES"' EXIT

crumb=$(curl -fs -c "$COOKIES" -u "$AUTH" "$JENKINS/crumbIssuer/api/json" \
  | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["crumbRequestField"] + ":" + d["crumb"])')

queue=$(curl -fs -b "$COOKIES" -u "$AUTH" -H "$crumb" -X POST -D - -o /dev/null \
  "$JENKINS/job/polaris-demo/buildWithParameters" --data-urlencode "BRANCH=$BRANCH" \
  | awk 'tolower($1)=="location:" {print $2}' | tr -d '\r')

echo ">> Queued build for branch $BRANCH, waiting..."
until build=$(curl -fs -u "$AUTH" "${queue}api/json" \
  | python3 -c 'import json,sys; e=json.load(sys.stdin).get("executable"); print(e["url"] if e else "")') && [ -n "$build" ]; do
  sleep 2
done
until curl -fs -u "$AUTH" "${build}api/json" | grep -q '"building":false'; do sleep 3; done

curl -fs -u "$AUTH" "${build}consoleText" | grep -v '^\[Pipeline\]'
echo ">> $build"
