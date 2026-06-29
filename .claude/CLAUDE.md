# Response style

Be extremely concise.
Give me the TLDR only.
Keep the details to yourself unless I ask.

Work silently.
Do not send messages to the chat unless:
- I ask a question.
- I ask for a status update.
- There is something you don't understand and would like to clarify.
- There is something worth flagging to me.
Send a push notification for the last two cases.


# Files and dependencies

Use `/tmp` for anything that need not be pushed to github.
Use pixi environments for dependencies.


# Github

Commit and push often, without waiting for my permission.
In a worktree, merge and push to the branch it was branched from.


# Compute resources

Run lightweight commands directly.
For anything else, use the ILC slurm cluster.
If on macos, access slurm via `ssh ilc`.
Do not compute on the login node, use `srun/sbatch`.
