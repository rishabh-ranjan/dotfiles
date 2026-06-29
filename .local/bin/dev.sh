#!/usr/bin/env bash
# Persistent dev tmux session on an ILC CPU node.
# Detach with Ctrl-b d. Release the node with: scancel -n dev-node
set -uo pipefail

if ! squeue -h -u "$USER" -n dev-node -t PENDING,RUNNING -o %i | grep -q .; then
  echo "starting dev-node ..."
  sbatch --account=infolab --partition=il-cpu --qos=il-cpu-long \
    --job-name=dev-node --nodelist=hyperturing1 \
    --nodes=1 --cpus-per-task=8 --mem=60G \
    --time=31-00:00:00 --output=/dev/null \
    --wrap='tmux new-session -d -s dev bash -l; exec sleep infinity' >/dev/null
fi

until jid=$(squeue -h -u "$USER" -n dev-node -t RUNNING -o %i | head -1)
[ -n "$jid" ]
do
  sleep 2
done

exec srun --jobid="$jid" --overlap --pty tmux attach -t dev
