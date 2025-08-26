# dotfiles

```bash
cd
git clone https://github.com/rishabh-ranjan/dotfiles
mv dotfiles/* dotfiles/.* .
rmdir dotfiles

curl -fsSL https://pixi.sh/install.sh | sh
.pixi/bin/pixi global sync
exit
```

```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install IlanCosman/tide@v6
tide configure --auto --style=Lean --prompt_colors='True color' --show_time='12-hour format' --lean_prompt_height='Two lines' --prompt_connection=Dotted --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Many icons' --transient=No
```

```bash
mkdir -p ~/.local/bin
cd ~/.local/bin
aria2c https://github.com/gokcehan/lf/releases/download/r36/lf-linux-amd64.tar.gz
tar -xzf lf-linux-amd64.tar.gz
rm lf-linux-amd64.tar.gz
cd -
```
