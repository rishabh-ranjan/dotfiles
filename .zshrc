# vim: set ft=zsh

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# fish="$HOME/micromamba/envs/sw/bin/fish"
fish="$HOME/.local/share/mamba/envs/sw/bin/fish"
if [ -x "$fish" ]
then
	export SHELL="$fish"
	unset fish
	exec "$SHELL"
fi
unset fish
