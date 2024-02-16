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

	source "$HOME/.mambaforge/etc/fish/conf.d/conda.fish"
	fish_add_path --path "$HOME/.mambaforge/bin"
	# conda activate base

	set -x WANDB_DIR "$HOME/.wandb"
	set -x WANDB_SILENT "true"
	set -x WANDB_CONSOLE "off"
end

if test -e "$HOME/.config/fish/custom.fish"
	source "$HOME/.config/fish/custom.fish"
end
