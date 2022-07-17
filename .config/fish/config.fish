if status is-interactive
	set -x LANG C.UTF-8
	set -x LC_ALL C.UTF-8

	if not functions --query tide
		fisher install IlanCosman/tide@v5
		echo 1 1 3 2 2 1 1 1 y | tide configure > /dev/null
	end

	fish_vi_key_bindings
	set -g fish_cursor_default block
	set -g fish_cursor_insert line
	set -g fish_cursor_visual underscore

	source "$HOME/.mambaforge/etc/fish/conf.d/conda.fish"
end

source "$HOME/.config/fish/custom.fish"
