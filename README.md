# dotfiles

Steps to terraform a new machine, mostly for personal reference:

1. Change to home directory:
	```bash
	cd ~
	```

2.  Install dotfiles:
	```bash
	git clone https://github.com/rishabh-ranjan/dotfiles
	cp -r dotfiles/* dotfiles/.* .
	```

	Errors like these are acceptable:
	```
	cp: '/home/rishabhr/dotfiles/..' and '/home/rishabhr' are the same file
	cp: cannot create regular file '/home/rishabhr/.git/objects/pack/pack-c20af10d644dc847dce7d997b0fbaedcfaf40108.pack': Permission denied
	cp: cannot create regular file '/home/rishabhr/.git/objects/pack/pack-c20af10d644dc847dce7d997b0fbaedcfaf40108.idx': Permission denied
	```

3. Install [mambaforge](https://github.com/conda-forge/miniforge#mambaforge):
	```bash
	aria2c https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh # for linux
	chmod +x Mambaforge-Linux-x86_64.sh
	echo -e "\nyes\n~/.mambaforge\nno" | ./Mambaforge-Linux-x86_64.sh
	```
	Use 'q' to exit the license.

4. Update the mamba base environment:
	```bash
	mamba env update -f ~/.config/mamba/base.yml --prune
	```

6. At this point, we can ssh into the machine again. As per the message, setup prompt:
	```bash
	fisher install IlanCosman/tide@v5
	echo 1 1 3 2 2 1 1 1 y | tide configure > /dev/null
	```
	Select `n` in `Configure tide prompt? [Y/n]`. The second line will configure prompt automatically.

	Login again for the prompt to take effect.

6. Install `neovim` from the Releases page <https://github.com/neovim/neovim/releases>. [TODO: detailed commands]

7. Clean up home directory:
	```bash
	rm -rf .bash_history .bash_logout .bashrc .cache .conda dotfiles Mambaforge-Linux-x86_64.sh
	ls -a
	```

8. Add ssh-key with:
	```bash
	ssh-copy-id <username>@<hostname>
	```

9. If required, add a custom rc for fish at `~/.config/fish/custom/<name>.fish` and link to it (or one of the existing ones) with:
	```bash
	ln -s ~/.config/fish/custom/<name>.fish ~/.config/fish/custom.fish
	```

10. Neovim should install plugins and do other setup automatically on first run:
	```bash
	nvim
	```
	Might give error on the first run because `plug.vim` is not recognized yet, but simply quitting and rerunning `nvim` fixes this.

11. Github login:
	```bash
	BROWSER=false gh auth login
	```
	Sometimes upgrading `gh` causes trouble. In that case, simply delete the `gh auth` lines from `~/.gitconfig`.

12. Update home directory permissions:
	```bash
	chmod 750 ~
 	```
 	This gives you read-write-execute, group users read-execute, and other users no permissions.
