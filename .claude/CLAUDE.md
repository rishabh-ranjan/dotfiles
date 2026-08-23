# Compute resources

Run lightweight commands directly.
For anything else, submit a slurm job using the `roach` skill.


# Files and dependencies

Use pixi environments for dependencies.

Use `~/scratch/<git_repo_name>/<expt_name>`
for experiment data and outputs.
Do NOT create any files or directories in `~/scratch`
or `~/` unless explicitly asked,
including as output files for your scripts.
Use `/tmp` for anything that need not be pushed to github.


# Github

Commit and push often, without waiting for my permission.
In a worktree, merge and push to the branch it was branched from.


# User input

If blocked on user input, send a push notification.
