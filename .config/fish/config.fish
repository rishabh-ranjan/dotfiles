if status is-interactive
	set -x EDITOR nvim
	set -x VISUAL nvim
	set -x LANG en_US.UTF-8
	set -x LANGUAGE en_US.UTF-8
	set -x LC_ALL en_US.UTF-8

	fish_vi_key_bindings
	set -g fish_cursor_default block
	set -g fish_cursor_insert line
	set -g fish_cursor_visual underscore

	set -U fish_greeting

	fish_add_path --path "$HOME/.local/bin"
	fish_add_path --path "$HOME/micromamba/envs/sw/bin"

	set -x WANDB_DIR "$HOME/.cache/"
	set -x WANDB_SILENT "true"
	set -x WANDB_CONSOLE "off"

	set -x PYTHONPATH "$HOME/.config/python"

	set -gx MAMBA_EXE "$HOME/.local/bin/micromamba"
	set -gx MAMBA_ROOT_PREFIX "$HOME/micromamba"
	$MAMBA_EXE shell hook --shell fish --root-prefix $MAMBA_ROOT_PREFIX | source

	micromamba activate $MY_ENV
end

fish_add_path /afs/cs.stanford.edu/u/ranjanr/.modular/bin