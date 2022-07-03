for brew in "$HOME/.linuxbrew" "/home/linuxbrew/.linuxbrew" "/usr/local"
do
	if [ -x "$brew/bin/brew" ]
	then
		eval "$($brew/bin/brew shellenv)"
		break
	fi
done
unset brew

fish="$(which fish)"
if [ -x "$fish" ]
then
	export SHELL="$fish"
	unset fish
	exec "$SHELL"
fi
unset fish
