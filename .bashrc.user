# vim: set ft=bash

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

if [[ $(hostname) = *.stanford.edu ]]
then
	export HOME="/lfs/local/0/ranjanr"
	cd
fi

export PATH="$HOME/.pixi/bin:$PATH"
export SHELL="$HOME/.pixi/bin/fish"
if [[ -x $SHELL ]]
then
	exec $SHELL
else
	unset SHELL
fi
