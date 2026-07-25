set fish_greeting

fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_visual underscore

set -x EDITOR nvim
set -x VISUAL nvim
set -x LANG en_US.UTF-8
set -x LANGUAGE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

set -x PYTHONPATH "$HOME/.config/python"

set -x WANDB_DIR "$HOME/.cache/"
set -x WANDB_CONSOLE "off"

# pixi is node-local, inside this home: on the cluster $HOME is a node-local
# dotfiles checkout (setup-node.sh), on the mac it is the usual home. Same path
# either way, so no host check is needed.
set -x PIXI_HOME "$HOME/.pixi"
fish_add_path --path $PIXI_HOME/bin

# Shared per-user storage; absent on the mac, hence the guard. Tokens are the
# one thing that must not be node-local. Interactive shells export them; batch
# jobs read the files themselves rather than inheriting the submitting env.
set -l dfs_home /dfs/user/ranjanr
if test -d $dfs_home/.secrets
	set -x GH_TOKEN (cat $dfs_home/.secrets/github)
	set -x GITHUB_TOKEN $GH_TOKEN
	set -x HF_TOKEN (cat $dfs_home/.secrets/huggingface)
	set -x HUGGING_FACE_HUB_TOKEN $HF_TOKEN
	set -x WANDB_API_KEY (cat $dfs_home/.secrets/wandb)
end

fish_add_path --path "$HOME/.local/bin"
