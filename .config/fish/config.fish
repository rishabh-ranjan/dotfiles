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

	set -x WANDB_DIR "$HOME/.cache/"
	set -x WANDB_SILENT "true"
	set -x WANDB_CONSOLE "off"

	set -x PYTHONPATH "$HOME/.config/python"
end
