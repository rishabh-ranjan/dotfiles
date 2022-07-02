if status is-interactive
	if not functions --query fisher
		curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
		fisher update
		echo 1 1 3 2 2 1 1 1 y | tide configure > /dev/null
	end

	fish_vi_key_bindings
	set -g fish_cursor_default block
	set -g fish_cursor_insert line
	set -g fish_cursor_visual underscore
end
