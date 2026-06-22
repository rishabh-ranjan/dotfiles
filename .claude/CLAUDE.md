# Response style

Be extremely concise.
Give me the TLDR only.
Keep the details to yourself unless I ask.


# File hygiene

Use `/tmp` for temporary work.
Use pixi environments for dependencies.
On ILC cluster, use `/dfs/user/ranjanr` for large files.


# Github

Commit and push often, without waiting for my permission.
In a worktree, merge and push to the branch it was branched from.


# How to run stuff

You can run lightweight stuff directly.
For anything else, use the ILC slurm cluster.


## ILC SLURM cluster resources

Use the following commands to get
an up-to-date understanding of ILC resources.

Login node is `ssh ilc`.
Do not compute on the login node, use `srun/sbatch`.

1. What am I allowed to use? (accounts, partitions, QoS) — ground truth
```bash
sacctmgr -s show user $USER format=account%20,partition%20,qos%60
```

2. QoS definitions: walls, priority, preemption, limits
```bash
sacctmgr show qos format=name%18,priority,maxwall,flags%30,maxtrespu%30
```

3. Partitions: which exist, default, state, walls, nodes
```bash
scontrol show partition          # or: sinfo -o "%P %a %l %D %N"
```

4. GPU/CPU/mem inventory + live usage
```bash
sinfo -N -o "%N %G %C %m %t"     # gres per node, CPU idle/alloc, mem, state
scontrol show node <node>        # full detail: Gres, GresUsed, features, TmpDisk
squeue                           # current queue
```

5. Node-local scratch path + quotas (run ON a compute node via srun)
```bash
df -h /lfs/local/0 2>/dev/null; ls -d /lfs/*/0    # find the node-local SSD
quota -s; df -h /sailhome /dfs/user/$USER         # shared quotas
```

## Use the cluster optimally

Monitor the free resources and
request slurm job partitions/QoS/resources wisely
to get allocations.
Feel free to cancel and re-submit jobs under different configs
if that would expedite the allocation time.
Overall criteria to optimize is the finish time of
all jobs relevant to the current session.

Ensure medium- to long- running jobs are pre-emptible.

## Debugging/development runs on ILC
