# ILC

`ClusterName=ilc`. Submit from an ILC node (where `~` is `/lfs/local/0/$USER`);
the `ilc` login host has no `~/scratch` and is not a submit host.
Code: `roach.slurm.clusters.ilc` (`ILC`, `AMPERE`, `AMPERE_LO`, `BLACKWELL`).
Monitor: [`scripts/ilc-watch.sh`](../scripts/ilc-watch.sh).

Partition `il`, account `infolab`. Per-node NVMe at `/lfs/local/0` (the node
environment puts `HOME`, pixi, caches and `TMPDIR` there); `/dfs/user/$USER`
is shared across nodes and slow; secrets in `/dfs/user/$USER/.secrets`.

## Nodes

| nodes | cards each |
| --- | --- |
| `ampere1`-`ampere9` | 8 x a100 |
| `blackwell1` | 8 x b200 |
| `hyperturing1`-`hyperturing2` | 10 x rtx8000 |
| `turing1`-`turing3` | 10 x 2080ti |
| `hyperion1`, `hyperion3` | 3-4 x titanxp |

A `Resources` for a b200 pins `nodelist="blackwell1"`, so those jobs can only
ever run on that one node. Nothing pins the amperes. The scheduler treats a
node with a full local disk as healthy, so a job placed there starts and then
wedges: keep a known-bad node out with `Resources.exclude`.

## Allocating a sweep

**The three qos tiers are a budget to spend, not a preference order over
cards.** Each cap is per user, counted across every job you have. Spend the
scarce, high-priority tiers on the fastest cards, then let the uncapped tier
take the rest. Fill in this order and stop when the sweep is placed:

| order | qos | budget | priority | wall | put it on |
| --- | --- | --- | --- | --- | --- |
| 1 | `il-interactive` | 2 gpus, any type | 1500 | 12h | **blackwell** — both of them |
| 2 | `il` | 10 gpus, **at most 2 b200** | 1000 | 7d | **2 blackwell, then ampere** for the other 8 |
| 3 | `il-lo` | uncapped (100) | 100 | 21d | ampere, and everything left over |

So a sweep's high-priority ceiling is **4 blackwell + 8 ampere = 12 jobs**;
job 13 onwards is `il-lo` and preemptible (GraceTime 300s). `il`'s two b200
are a separate sub-cap, not a slice of the ten — spending them costs 2 of the
10 as well.

**Priority buys the next card that frees, not a card.** A high-priority job
outranks every `il-lo` job in the queue, but it cannot take a card from a
running non-preemptible one — and `il` and `il-interactive` jobs are exactly
that. So before spending a tier on blackwell, check when a b200 will actually
free:

```
squeue -p il -h -t RUNNING -o "%u %b %M %l %q" | grep b200   # elapsed vs limit
```

Subtract elapsed from the limit for each of the 8 cards. If the soonest is
further out than the job itself would take on an ampere, **put the high tiers
on amperes instead** — a slower card now beats a faster card in four hours.
blackwell1 is one node of 8 shared with everyone, so this is the common case,
not the exception. Note it in the submit script when you do, with the numbers
you read.

Two other things that *are* reasons to place a job somewhere else:

- **Your own jobs holding the cap.** `il`'s ten count across all your sweeps,
  so a fine-tuning sweep already holding six leaves four here. Subtract what
  you hold before you spend.
- **A job that cannot resume having to fit the wall clock.** `il-interactive`
  is 12 hours and `il` is 7 days; a run that checkpoints resumes through both,
  one that does not restarts from the top. Do not put a 15-hour eval in a
  12-hour slot.

### A reservation is il-lo only

A node reserved for you is yours whatever tier the job asks for: nobody else
can take its cards, and nothing preempts you there. So a `il` or
`il-interactive` job on a reserved node **spends a capped, scarce slot on a
card it would have got for free** — put `il-lo` jobs there and keep the high
tiers for the contended pool.

A reserved node is also out of general scheduling, so a job reaches it only
with `--reservation=<name>` (`Resources.reservation`), and a job that sets it
is confined to that reservation. A reservation that has ended is a
`--reservation` flag that fails the submission: read it every time.

```
scontrol show res                     # name, nodes, end time
```

### Read the cluster, every submission

```
sacctmgr -np show qos format=Name,Priority,MaxTRESPU,MaxWall,Preempt
squeue -u $USER -h -o "%q %b %T" | sort | uniq -c   # what you already hold, by tier
squeue -u $USER -o "%.8i %.30j %.14q %.9T %R"       # your pending, with reasons
sinfo -p il -N -o "%N %G %C %t"                     # what exists, what is down
squeue -p il -h -t RUNNING -o "%N %b" | sort | uniq -c
scontrol show node blackwell1 | grep -E "CfgTRES|AllocTRES|State"   # b200 free = Cfg - Alloc; RESERVED = not yours
squeue -p il -h -t RUNNING -o "%u %b %M %l %q"      # elapsed vs limit: when a card frees
```

Then write the three rows out before deciding anything:

| tier | cap | you hold | free |
| --- | --- | --- | --- |
| `il-interactive` | 2 gpus | ? | ? |
| `il` | 10 gpus, ≤2 b200 | ? | ? |
| `il-lo` | uncapped | — | — |

### Rebalancing, ILC specifics

- **Re-ask the blackwell question, both ways.** A high-tier job still pending on
  blackwell is a job you are paying priority for and getting nothing from: move
  it to an ampere. A high-tier job on an ampere when b200 cards have since freed
  is the same mistake mirrored: move it back. Read the remaining wall clocks, do
  not guess.
- **A freed `il-interactive` slot is worth a card check, not an assumption.**
  Having room in the tier does not mean blackwell1 has a b200 free; read
  `AllocTRES` before spending it.
- **`CfgTRES - AllocTRES > 0` is not a card you can have.** A spare b200 may be
  held by a reservation (`State=...RESERVED`), or planned by backfill for a
  higher-priority pending job — which shows up in no query at all. A blackwell
  submission is not done until you have seen it start: check its pending
  reason within a minute, and move it to an ampere the moment it reads
  `ReqNodeNotAvail`.
- `sbatch --test-only` shape for a b200:

  ```
  sbatch --test-only -p il -A infolab -q il-lo -t 4:00:00 \
      --gres=gpu:b200:1 --cpus-per-task=36 --mem=375000M --nodelist=blackwell1 probe.sh
  # sbatch: Job N to start at 2026-08-13T00:56 ... on nodes blackwell1
  ```

## Resource shapes

The presets in `roach.slurm.clusters.ilc` are the usable shapes and each
carries the constraint that forced it. Things that bite when writing a
`Resources` by hand:

- `il` caps wall clock at 7d; `il-lo` allows 21d; `il-interactive` 12h.
- 14 cpus per gpu when not `--exclusive`; an `--exclusive` a100 job gets all
  128 cores and, with `mem=None`, all 2017232M — an explicit `--mem` is capped
  lower.
- `DefMemPerGPU=240000M`: with `mem` a job can hold at most RealMemory / that
  many GPUs (3 on a 770G node); use `mem_per_gpu` to hold a whole node's cards.
- The ampere nodes carry unrelated cpu-only jobs; demanding `--exclusive`
  there just queues.
