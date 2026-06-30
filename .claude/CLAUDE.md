# Response style

Be extremely concise.
Give me the TLDR only.
Keep the details to yourself unless I ask.


# Files and dependencies

Use `/tmp` for anything that need not be pushed to github.
Do not pollute my filesystem with any logs, scripts, outputs, etc.
Use pixi environments for dependencies.


# Github

Commit and push often, without waiting for my permission.
In a worktree, merge and push to the branch it was branched from.


# Compute resources

Run lightweight commands directly.
For anything else, use the ILC slurm cluster.
If on macos, access slurm via `ssh ilc`.
Do not compute on the login node, use `srun/sbatch`.
`/dfs/user/ranjanr` is shared across nodes,
but it is slow.
Use node-local `/lfs/local/0/ranjanr` for code, caches, environments, and temporary files.
Keep github repos in `/lfs/local/0/ranjanr/clones`,
caches will automatically use `/lfs/local/0/ranjanr/.cache`,
pixi will automatically create environments in `/lfs/local/0/ranjanr/.pixi`,
keep temporary files in `/tmp/ranjanr`.
Only use `/dfs/user/ranjanr` for things that need to be shared.
This does not necessarily include datasets, which can be kept node-local.
