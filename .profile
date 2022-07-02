for DIR in "$HOME/.linuxbrew" "/home/linuxbrew/.linuxbrew" "/usr/local"
do
	if [ -x "$DIR/bin/brew" ]
	then
		eval "$($DIR/bin/brew shellenv)"
		break
	fi
done

export SHELL="$(which fish)"
exec "$SHELL"
