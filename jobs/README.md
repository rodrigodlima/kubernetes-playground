# Jobs & CronJobs

Demonstrates Kubernetes [Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/) (run-to-completion) and [CronJobs](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/) (scheduled execution).

## Setup

```bash
kubectl apply -f namespace.yaml
```

---

## 1. Simple Job (`job-hello.yaml`)

Runs a single Pod to completion.

```bash
kubectl apply -f job-hello.yaml

# Watch it complete
kubectl -n jobs-demo get jobs -w

# Read the output
kubectl -n jobs-demo logs job/hello
```

Key fields:
- `restartPolicy: Never` — failed Pods are not restarted in place; a new Pod is created instead.
- `backoffLimit: 2` — give up after 2 retries.
- `ttlSecondsAfterFinished: 120` — auto-delete the Job 2 minutes after completion.

---

## 2. Parallel Job (`job-parallel.yaml`)

Runs 6 completions, 3 in parallel.

```bash
kubectl apply -f job-parallel.yaml

# Watch pods spawn in batches of 3
kubectl -n jobs-demo get pods -w

# Status
kubectl -n jobs-demo get job parallel-workers
```

Key fields:
- `completions: 6` — total successful Pods required.
- `parallelism: 3` — maximum Pods running at once.

---

## 3. Failing Job (`job-failing.yaml`)

Exits with code 1 every run — exercises `backoffLimit` retries.

```bash
kubectl apply -f job-failing.yaml

# Watch the Job retry up to backoffLimit times
kubectl -n jobs-demo get pods -w

# Final state: BackoffLimitExceeded
kubectl -n jobs-demo describe job failing
```

---

## 4. CronJob (`cronjob-every-minute.yaml`)

Schedules a Job every minute (standard cron syntax).

```bash
kubectl apply -f cronjob-every-minute.yaml

# Check schedule
kubectl -n jobs-demo get cronjob every-minute

# Watch new Jobs appear each minute
kubectl -n jobs-demo get jobs -w

# Read latest run's logs
kubectl -n jobs-demo logs -l job-name -c clock --tail=20

# Trigger a manual run (without waiting for schedule)
kubectl -n jobs-demo create job --from=cronjob/every-minute manual-run-1
```

Key fields:
- `schedule: "*/1 * * * *"` — every minute.
- `concurrencyPolicy: Forbid` — skip new run if previous still running. Alternatives: `Allow`, `Replace`.
- `successfulJobsHistoryLimit: 3` — keep last 3 successful Jobs for inspection.

---

## Cleanup

```bash
kubectl delete namespace jobs-demo
```

## Files

| File | Description |
|------|-------------|
| `namespace.yaml` | Namespace `jobs-demo` |
| `job-hello.yaml` | Single-Pod Job that prints and exits |
| `job-parallel.yaml` | Job with 6 completions, 3 in parallel |
| `job-failing.yaml` | Job that always fails — exercises `backoffLimit` |
| `cronjob-every-minute.yaml` | CronJob running every minute |
