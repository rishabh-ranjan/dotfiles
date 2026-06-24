function fish_user_key_bindings
    # Alt+Backspace deletes the previous word (all vi modes)
    bind -M insert \e\x7f backward-kill-word
    bind -M default \e\x7f backward-kill-word
    bind -M visual \e\x7f backward-kill-word
end
