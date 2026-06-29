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
