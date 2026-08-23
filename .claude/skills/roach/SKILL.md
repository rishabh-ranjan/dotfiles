---
name: roach
description: Slurm jobs through the roach package (github.com/rishabh-ranjan/roach) — submitting, watching, rebalancing and recovering runs on the supported clusters (ILC, and Marlowe on the human's instruction). Use whenever sbatch, squeue, srun, a sweep, a pending or preempted job, a cluster budget, or roach itself comes up.
---

# roach on slurm

`roach.slurm` runs a python function as a slurm job: one job, one rank per GPU,
resumable across preemption and the wall clock. Its README
(`roach/slurm/README.md` in the installed package, or on GitHub) is the
reference for what a job does, the clone protocol, and the read-only rule; this
skill is the workflow around it and what each cluster is like.

## 1. Which cluster

**The cluster is the human's call alone.** A submission goes to ILC unless
the instruction names Marlowe. Marlowe spends a metered allocation shared
with the group and is never chosen on your own initiative, never as a
fallback when ILC is full, and never with more than the human said.

| cluster | read | code | driven from |
| --- | --- | --- | --- |
| ILC | [clusters/ilc.md](clusters/ilc.md) | `roach.slurm.clusters.ilc` | an ILC node (this session's host) |
| Marlowe | [clusters/marlowe.md](clusters/marlowe.md) | `roach.slurm.clusters.marlowe` | here, over `ssh marlowe` |

Every cluster exists in exactly those two places, under one name: the skill
file holds the budget, the topology and the tactics; the roach module holds the
node environment and the `Resources` presets. Adding a cluster means adding
both. If the cluster is neither here nor there, stop and say so.

Sessions run on an ILC node, where `~` is the node-local home and `~/scratch`
the shared store; every path a submit script passes is written in those
terms and means the same on every cluster. The `ilc` login host is not a
submit host (its `~` is AFS and has no `scratch`). Never compute on a login
node; everything that is not a lightweight command goes through `sbatch`.

## 2. Submit

```python
from roach.slurm import Resources, submit
from roach.slurm.clusters.ilc import ILC, AMPERE   # the cluster's module

submit("pkg.module:function", args={...}, resources=AMPERE, cluster=ILC,
       name=..., job_env=..., repo_root=...,
       log_root="~/scratch/<repo>/<expt>/slurm-logs",
       clone_root="~/roach_clones", secrets_dir="~/scratch/.secrets")
```

`~` in those three is the *cluster's* home: the same strings submit to
Marlowe with `cluster=MARLOWE, resources=H100`.

- **Submit it, do not `srun` it**, a two-minute probe included. The repo lives
  on the submitting host's local disk, which the compute node does not have;
  an `srun` from inside an allocation is a step of that job and inherits its
  limits; `Resources` carries the account, partition and constraint.
- **Commit and push before submitting**: the job clones that commit, and
  `submit()` refuses a dirty or unpushed tree.
- **A probe is a submission like any other**: a target in the repo, committed,
  submitted with the resources it actually needs.
- **Write nowhere but the paths you pass the entry point.** The clone is shared
  by every job at that commit on a node and is read-only while jobs run.
- **`/tmp` is for a job's own scratch on its node, named after the run** —
  never for code, never for anything to be read afterwards (it is node-local,
  and a `#SBATCH -o /tmp/...` log vanishes).
- **Take the best slots available, absent an explicit instruction otherwise** —
  where "best" is what gets the sweep finished soonest, not what has the
  fastest card. The cluster page says how to allocate.
- **Work the resource plan out fresh, every submission.** What a submit script
  asked for last time is a record of a different cluster state and a different
  instruction, not a default to inherit. Read the cluster, subtract what you
  already hold, apply the cluster's budget, and write today's answer into the
  file.

### Iterating: hold the allocation

When a run is being debugged -- it hung, it was cancelled, the next attempt
is minutes away -- do not queue every attempt as a job: `hold(resources,
cluster=..., name=..., log_root=...)` queues a job that takes the node and
sleeps, and once it is running every `submit(..., inside=<its id>)` starts
at once as a step of it. Same script, same logs (`<run_id>_<holder>.out`),
no requeue (a step dies with the holder). The holder is charged whether or
not a step runs in it: `scancel` it the moment an attempt trains correctly,
and submit the real run as a job of its own. On a metered cluster the human
decides to hold, as for any other placement.

## 3. Watch every job you submit

**A submission is not done when `sbatch` returns — it is done when you have
seen the jobs run.** Nothing alerts you, and a broken run holds its GPU for
the full wall clock while filling the shared filesystem. Reporting a submission
as finished before the checks below have passed is reporting work that was not
done.

**Waiting for the jobs to exit is not monitoring.** A command that blocks until
the queue is empty reports the end and nothing else: a run that stalled at hour
two, a job preempted back to the start, a log that stopped moving, all of it
arrives as one notification long after it could have been acted on. Monitoring
is a *repeated* check while the jobs are still running, and every round of it
ends in an answer to "is each job further along than last time?".

**Start one persistent monitor, not a chain of one-shot waits.** Arm a single
poll loop over the queue that runs for the life of the sweep and emits a line
per round; re-arming a timer at the end of every round is a fresh chance to
forget, and the first round nobody starts is the round the watch ends — which
looks exactly like a sweep that is fine. A stated interval with no live monitor
behind it is not a watch.

**Two monitors: one edge-triggered, one heartbeat.** A loop that speaks every
round has to be slow enough not to drown you, and a slow loop is exactly what
misses a slot that freed a minute after it looked. Split the two jobs: poll
often but **emit only on a change** — a tier or a card that has room, a pending
reason that will never start, a job that went from running back to the queue, a
reservation that moved or vanished — and run a second, quarter-hour loop that
prints one line whatever happened, so silence from the first is never mistaken
for a watcher that died. Keep the edge monitor's state between rounds and
compare against it. Each cluster page ships a `scripts/<cluster>-watch.sh`
that is this shape with that cluster's counters in it: start from it.

**Make the monitor watch the budget, not just the jobs.** A high-tier slot
frees the instant any job of yours ends, which is far more often than any sane
interval. Count the running jobs per tier against the cluster's budget every
round and emit a distinct line when a tier has room while anything of yours is
pending; that line is a [promotion to make now](#4-rebalance-while-it-runs),
not a status update. A sweep of short jobs turns tiers over every few minutes,
so poll minutes, not quarter-hours.

**Count a tier as claimed, not as running.** A pending job of yours on a capped
tier already owns one of its slots and starts the moment a card frees, so
counting only `RUNNING` reports the tier free while your own queue is what it
is waiting behind — and every promotion you make on that reading overshoots the
cap.

The loop has to end by itself, too: make it emit on the queue going empty, and
on the [pending reasons](references/pending.md) that mean a job will never
start, not only on progress. Silence has to mean "still going", never "the
watcher stopped".

Check right after submitting, again once the runs are past startup — a few
minutes, and long enough that progress lines must have appeared by then — and
then **on a fixed interval until every job has finished**, an interval short
enough to catch a stall in the same session it happens. A sweep that runs for
days is watched for days. Every time:

- read the log of **every** job, not a sample of them, and confirm each one
  reaches its progress lines and they move. A log that stops after startup
  output is not yet evidence of anything;
- **compare against the previous round, not against zero.** The check that a
  job is alive is that its last line is *newer* than the one you saw last time.
  A run whose log has not moved since the previous round is stalled, whatever
  slurm says its state is;
- know **what each job's progress line costs**, so a gap between lines can be
  called normal or not: a training step is seconds, an eval pass over a whole
  test split is minutes to hours;
- `ls -laS` the log directory and `df -h` the output filesystem;
- **recount what is free and what you hold**, and move a pending job up if a
  better slot appeared — see [Rebalance](#4-rebalance-while-it-runs). A round
  that only looked at your own logs missed half of what changed;
- cancel what is broken, delete its logs and scratch, fix the cause, resubmit
  — **never its checkpoints**: `resume.pt` is the only way to continue a run,
  and no instruction authorises deleting one; only the user does, explicitly,
  naming the run.

**A pending job is a job to diagnose, not a job to wait for.** `squeue -u
$USER -o "%.8i %.30j %.14q %.9T %R"` prints a reason beside every one, and only
some of them mean the queue is working: [references/pending.md](references/pending.md).
Reporting a sweep as submitted while its jobs sit on a reason that will never
clear is reporting work that was not done.

Jobs that are still queued are not off the hook: they get the same checks once
they start. The watch ends only when every job you submitted has completed or
been cancelled — not when they have all been seen running once.

## 4. Rebalance while it runs

**An allocation is right when it is made and wrong an hour later.** What is
free changes without you: other people's jobs end, your own finish and hand
back your cap, and a preempted job of yours goes back to the queue. A sweep
left alone spends the rest of its life on the lowest tier behind everyone else.

So a monitoring round has **two** questions, not one. The first is per job —
is each one further along than last round? The second is about the cluster:
*has what is free changed, and is there a better slot for something of mine
now?* Ask it every round, whether or not anything of yours looks wrong. The
cluster page has the supply commands.

**Any pending job of yours plus any free card is a move you have not made.**
That pair is the whole trigger; it does not need a reason beyond itself. The
most common way it appears is not someone else finishing — it is **your own job
completing and handing your cap back**, which is invisible unless you recount.

- **Recount every tier top down, as a fresh run of the cluster's allocation
  rule** — not a patch to the placement you already have. Write the tier table
  out each round (cap, you hold, free) before deciding anything. **The top tier
  is the one most often missed**: it is the smallest, so it empties the moment
  its jobs finish, and it empties silently.
- **Spend a freed tier on the jobs with the most left to do**, not on whatever
  is nearest to hand — the long pole finishes the sweep.
- **Ask slurm when a job would start, instead of guessing from free cards.**
  `sbatch --test-only <flags> script.sh` prints the planned start of a job it
  does not submit. Run it once per qos. It ignores your own per-user caps, so a
  start time on a tier you have already filled is not a slot you can take, and
  **it does not model `--reservation`** — on a reservation the only honest test
  is a real one-minute job. Put it inside the monitor, gated on a start time
  within the next few minutes, so free-card noise does not train you to ignore
  the one time it matters.
- **A free card is a candidate to try, never capacity to plan around.** It may
  be held by a reservation or *planned* by backfill for a higher-priority
  pending job, which no query shows; only a submission finds out, as
  `ReqNodeNotAvail`. A job pinned by `nodelist` sits on that forever, so check
  its reason within a minute of submitting and move it if it reads that.
- **If a tier has room while anything of yours is pending**, cancel the pending
  one and resubmit it into the tier that freed — a pending job has lost nothing
  by being moved.
- **Move a *running* job only when what it loses is smaller than what it
  gains**: a run that checkpoints loses minutes, an eval that does not loses
  everything it has done, a pending job loses nothing. Prefer moving your
  youngest job when you need to free a slot of your own.
- **Move a checkpointing run by its `run_id`, never by starting it over.**
  `submit(..., run_id=<the cancelled run's id>)` reuses that run's output
  directory, so the new job picks its checkpoint back up. Read the id off the
  submission's own output, check the checkpoint's mtime is recent, cancel, then
  submit. Confirm the new log says it resumed at the step it was at — a job
  that reports a fresh start has silently restarted from zero and has to be
  caught in that round, not later.
- **Only ever move your own jobs.** Other sessions' and other people's jobs
  count against the same per-user cap and are part of the arithmetic, but they
  are never yours to cancel.
- Leave the budget under-spent only deliberately, and say why.

**Set the interval from the job, not from habit.** The check has to be more
frequent than the thing it is watching for: a sweep of four-minute evals needs
minutes, a multi-day run does not. If your jobs are shorter than your
monitoring interval, you are guaranteed to miss every card that freed.

## 5. Preemption is a state change to act on

A preempted job is not a job that carries on. Watch for it explicitly — a job
whose `%M` elapsed went *backwards* between rounds, or whose `%R` is a requeue
reason, has restarted:

```
squeue -u $USER -h -o "%.8i %.30j %.9T %.10M %R"   # elapsed shrank = it restarted
sacct -u $USER -X --format=JobID,JobName%30,State,Elapsed --starttime now-1day
```

What it costs decides what to do. **A run that checkpoints resumes and has lost
minutes** — leave it, but count the restart. **A job that does not checkpoint
restarts from the top**, so one that has been preempted once on the preemptible
tier will lose everything again, and it is the first thing to promote when a
non-preemptible slot frees. Being preempted twice on the same tier is a
placement to change, not luck to retry.

## 6. When it is over

Kill every job of the experiment's — running, pending and requeued alike —
and nothing else's. Delete its logs and scratch on every filesystem it touched
(node-local disks included: nothing sweeps them for you); its checkpoints stay.
Reclaim clone space only by hand, only when a disk is actually full, and never
while a job is running from that clone (`rm -rf <clone_root>/repo-*`; see the
roach README).
