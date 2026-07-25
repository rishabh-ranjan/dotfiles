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

# Shared per-user storage on the cluster; absent on the mac, so everything
# below is guarded on the directory existing and this file stays portable.
set -l dfs_home /dfs/user/ranjanr

# One pixi install for the whole cluster: the binary and the global CLI tools
# live on shared storage, so no node needs setting up. Project environments are
# still node-local -- detached-environments = false in $PIXI_HOME/config.toml
# keeps each env inside its project dir, and projects live on node-local disk.
if test -d $dfs_home/.pixi
	set -x PIXI_HOME $dfs_home/.pixi
else
	# mac (and anywhere without shared storage): the usual per-user install.
	set -x PIXI_HOME "$HOME/.pixi"
end
fish_add_path --path $PIXI_HOME/bin

# Tokens, readable from every node. Interactive shells export them; batch jobs
# read the files themselves rather than inheriting the submitting env.
if test -d $dfs_home/.secrets
	set -x GH_TOKEN (cat $dfs_home/.secrets/github)
	set -x GITHUB_TOKEN $GH_TOKEN
	set -x HF_TOKEN (cat $dfs_home/.secrets/huggingface)
	set -x HUGGING_FACE_HUB_TOKEN $HF_TOKEN
	set -x WANDB_API_KEY (cat $dfs_home/.secrets/wandb)
end

fish_add_path --path "$HOME/.local/bin"
