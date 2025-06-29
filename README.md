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
```
