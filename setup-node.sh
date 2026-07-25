#!/bin/bash
# Set up (or update) this node so it meets the assumptions everything else
# makes: a dotfiles checkout as the node-local home, and a node-local pixi with
# the global CLI tools installed. Idempotent -- safe to run on a fresh node or
# on one that is already set up.
#
#   bash setup-node.sh            # set up what is missing
#   bash setup-node.sh --update   # also pull dotfiles and re-sync global tools
#
# Without --update this is also the verification path a batch job runs before
# doing real work: on a healthy node it is a handful of stat calls and touches
# the network not at all, and it exits non-zero if the node cannot be brought up
# to spec. --update is for you, not for jobs -- it pulls, which would let a node
# change under a running job.
#
# On a node that has never been touched, bootstrap it straight from GitHub:
#
#   curl -fsSL https://raw.githubusercontent.com/rishabh-ranjan/dotfiles/main/setup-node.sh | bash
#
# Only system git and curl are needed to get started. Durable state that is NOT
# node-local (API tokens) lives in /dfs/user/$USER and is not touched here.

set -euo pipefail

DOTFILES_URL=https://github.com/rishabh-ranjan/dotfiles
# NODE_HOME is overridable only so the cold-start path can be exercised
# somewhere harmless; nothing in normal use sets it.
NODE_HOME=${NODE_HOME:-/lfs/local/0/${USER:-$(id -un)}}
UPDATE=0
[[ ${1:-} == --update ]] && UPDATE=1

say() { echo "setup-node: $*"; }
die() { echo "setup-node: $*" >&2; exit 1; }

command -v git >/dev/null || die "no git on PATH"
command -v curl >/dev/null || die "no curl on PATH"

# Several jobs can land on a fresh node at once and all decide to set it up.
# Serialize them: the first one does the work, the rest wait and then find a
# node that is already set up.
LOCK=${TMPDIR:-/tmp}/.setup-node.lock
mkdir -p "$(dirname "$LOCK")"
exec 9>"$LOCK"
flock 9 || die "cannot take $LOCK"

# ---- 1. node-local home == dotfiles checkout ----
if [[ ! -d $NODE_HOME/.git ]]; then
    say "cloning dotfiles into $NODE_HOME"
    mkdir -p "$NODE_HOME" || die "cannot create $NODE_HOME on $(hostname -s)"
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles.XXXXXX")
    git clone --quiet "$DOTFILES_URL" "$tmp/dotfiles"
    # Move the repo in around whatever the node already has in that dir,
    # rather than refusing to clone into a non-empty directory.
    mv "$tmp/dotfiles/.git" "$NODE_HOME/.git"
    git -C "$NODE_HOME" checkout --quiet -- .
    rm -rf "$tmp"
elif (( UPDATE )); then
    say "updating dotfiles in $NODE_HOME"
    git -C "$NODE_HOME" pull --rebase --quiet
fi

export HOME=$NODE_HOME
export PIXI_HOME=$HOME/.pixi

# ---- 2. node-local pixi ----
if [[ ! -x $PIXI_HOME/bin/pixi ]]; then
    say "installing pixi into $PIXI_HOME"
    curl -fsSL https://pixi.sh/install.sh | PIXI_HOME=$PIXI_HOME bash >/dev/null
    [[ -x $PIXI_HOME/bin/pixi ]] || die "pixi install did not produce $PIXI_HOME/bin/pixi"
fi
export PATH=$PIXI_HOME/bin:$PATH

# ---- 3. global CLI tools ----
# The manifest and pixi config are tracked in the dotfiles repo, so this
# installs exactly the same tool set on every node. `global sync` is a no-op
# when the node already matches the manifest, but it does hit the network, so
# only run it when something is missing or --update was asked for.
missing=()
for tool in fish git nvim tmux rg ag python; do
    [[ -x $PIXI_HOME/bin/$tool ]] || missing+=("$tool")
done
if (( UPDATE )) || (( ${#missing[@]} )); then
    (( ${#missing[@]} )) && say "missing global tools: ${missing[*]}"
    say "pixi global sync (this downloads; minutes on a fresh node)"
    pixi global sync
fi

# ---- 4. node-local dirs everything else assumes ----
mkdir -p "$HOME/.cache" "/tmp/$USER"

# ---- 5. it worked, or nobody should trust this node ----
for tool in fish git nvim tmux rg ag python; do
    [[ -x $PIXI_HOME/bin/$tool ]] || die "$tool still missing on $(hostname -s)"
done

say "ok: $(hostname -s) HOME=$HOME pixi=$(pixi --version)"
