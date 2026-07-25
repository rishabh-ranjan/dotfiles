#!/bin/bash
# Check that this node meets the standard assumptions, and reinstate them if it
# does not. Cheap and offline on a healthy node (a handful of stat calls), so
# any slurm job can call it before doing real work:
#
#   bash /lfs/local/0/$USER/verify-node.sh
#
# Exits non-zero, loudly, if the node cannot be brought up to spec -- better a
# job that dies in the first seconds than one that runs degraded for hours.

set -euo pipefail

USER=${USER:-$(id -un)}
NODE_HOME=/lfs/local/0/$USER
SHARED=/dfs/user/$USER
SETUP_URL=https://raw.githubusercontent.com/rishabh-ranjan/dotfiles/main/setup-node.sh

die() { echo "verify-node: $*" >&2; exit 1; }

check() {
    [[ -d $NODE_HOME/.git ]] || return 1
    [[ -x $NODE_HOME/.pixi/bin/pixi ]] || return 1
    for tool in fish git nvim tmux rg ag python; do
        [[ -x $NODE_HOME/.pixi/bin/$tool ]] || return 1
    done
    return 0
}

if ! check; then
    echo "verify-node: $(hostname -s) is not set up; running setup" >&2
    if [[ -f $NODE_HOME/setup-node.sh ]]; then
        bash "$NODE_HOME/setup-node.sh"
    else
        # Nothing node-local to run yet -- bootstrap from GitHub.
        curl -fsSL "$SETUP_URL" | bash
    fi
    check || die "$(hostname -s) still not set up after running setup-node.sh"
fi

# Shared state that no amount of node setup can create.
[[ -d $SHARED ]] || die "$SHARED not mounted on $(hostname -s)"
for s in wandb huggingface github; do
    [[ -r $SHARED/.secrets/$s ]] || die "missing secret $SHARED/.secrets/$s"
done

echo "verify-node: ok on $(hostname -s)"
