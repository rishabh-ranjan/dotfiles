# Marlowe

Stanford's DGX H100 SuperPOD. `ClusterName=slurm` (not distinctive; the
submit host is what identifies it). Code: `roach.slurm.clusters.marlowe`
(`MARLOWE`, `H100`, `H100_PREEMPT`). Monitor:
[`scripts/marlowe-watch.sh`](../scripts/marlowe-watch.sh).

**Only on the human's instruction.** A submission goes to Marlowe when the
instruction names it, with the partition, account and node count the human
gave. There is no budget rule to apply and no tier to fill: `batch` spends a
metered GPU-hour allocation shared by the whole group, and how much of it a
sweep may take is the human's call every time.

## Remote

The session never runs on Marlowe. `MARLOWE.submit_host="marlowe"` makes
`submit()` and `Job.state` go over ssh, and every command on this page is
run the same way:

```
ssh marlowe 'export PATH=/cm/shared/apps/slurm/current/bin:$PATH SLURM_CONF=/cm/shared/apps/slurm/var/etc/slurm/slurm.conf; squeue -u $USER'
```

(`M='ssh marlowe export PATH=... SLURM_CONF=...;'` and then `$M squeue ...`
is the shape the watch script uses.) The host is Duo-gated; ssh works
non-interactively only through the ControlMaster in `~/.ssh/config`. Check
`ssh -O check marlowe` first: if there is no master, ask the human to run
`! ssh marlowe true` once and continue. Never retry a hanging ssh.

## Nodes and storage

31 identical nodes `n[01-31]`: 8 x H100-80G, 112 cores, 1950000M, 1 TB
`/dev/shm`. Every partition spans all of them.

| path | what | use for |
| --- | --- | --- |
| `~` = `/users/$USER` | shared NFS home, a dotfiles checkout, small quota | nothing of size |
| `~/scratch` -> `/scratch/m000137-pm06/$USER` | Lustre, the allocation's 40 T / 12 M inodes | logs, checkpoints, data, `~/.cache`, `~/roach_clones` |
| `/local_scratch/$USER.$SLURM_JOB_ID` | per-job dir on the node's 28 T NVMe, deleted by the epilog | `TMPDIR`, set by the env; nothing that outlives the job |
| `/tmp`, `/local` | the node's root disk, routinely full | never |

`~/roach_clones` is on Lustre. Measured on the first roach job there: the
first job at a commit spends ~2 min in `prepare:` (pixi install plus the rust
build), a later one seconds; a cold `import torch` on a node that has not
seen the environment is ~22 s (5 s warm), and `time_to_first_step` came 21 s
after the ranks started. Those are the expected gaps in a log, not stalls.

## Partitions

| partition | qos | account | max time | max nodes | preemption |
| --- | --- | --- | --- | --- | --- |
| `preempt` | `normal` | `marlowe-m000137` | 12 h | unlimited | requeued with 900 s grace whenever `batch`/`hero` wants the node; at most 96 GPUs per account |
| `batch` | `medium` | `marlowe-m000137-pm06` | 2 d | 16 | none; billed |
| `hero` | `large` | (none of ours) | 30 d | 31 | — |

A `pm06` job on `preempt` is still billed. `batch` does not preempt
`preempt` jobs of the same user any differently: a `preempt` job of yours is
requeued at any moment, **including after it has finished its work and
before the batch script exits** — `Restarts>0` with `PENDING` is a job that
will run again from its checkpoint, or from the top if it has none. Cancel
it if it is done.

The allocation is one pool, no per-user caps, first come first served:

```
$M sshare -A marlowe-m000137-pm06 -l -n -o Account,GrpTRESMins,GrpTRESRaw%200 | head -1   # gres/gpu= minutes: limit, used
```

`AssocGrpGRESMinutes` as a pending reason means the pool is spent.

## Read the cluster, every submission

```
$M squeue -u $USER -o "%.8i %.30j %.10P %.9T %.10M %R"        # yours, with reasons
$M sinfo -p batch -o "%P %D %C %t"                              # what is up
$M squeue -p batch,preempt -h -o "%P %T" | sort | uniq -c       # queue depth
$M scontrol show res                                            # maintenance reservations
$M sbatch --test-only -A marlowe-m000137-pm06 -p batch -N 1 --gpus=8 -c 112 -t 2-00:00:00 x.sh   # planned start
```

Both partitions are contended: an 8-GPU `batch` job has been quoted ~8 h out,
a `preempt` one ~12 h. Priority here is fair-share across projects; there is
no free card to find and nothing to promote between tiers. Rebalancing on
Marlowe is only: move a `preempt` job that keeps getting requeued to `batch`
**if the human said `batch` is allowed**, and cancel what is done.

## Resource shapes

The presets are whole nodes (`gpus="8"`, `cpus_per_task=14`, `exclusive=True`,
`mem=None` -> 1456000M via `DefMemPerCPU=13000`). `nodes=N` up to 16 on
`batch`. A smaller job is `dataclasses.replace(H100, gpus="1",
cpus_per_task=14, exclusive=False)`; the partition's default memory is then
13000M per cpu. `TaskPlugin=task/cgroup`, so `nproc` in a task is its
`cpus_per_task`. `ulimit -l` is unlimited by default. Internet works from
compute nodes.
