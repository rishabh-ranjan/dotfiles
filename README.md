# dotfiles

The node-local home (`/lfs/local/0/$USER`) is a checkout of this repo plus its
own pixi install. `setup-node.sh` creates both and is idempotent, so setting up
a node, updating one, and checking one are the same command:

```bash
curl -fsSL https://raw.githubusercontent.com/rishabh-ranjan/dotfiles/main/setup-node.sh | bash
bash ~/setup-node.sh --update   # pull dotfiles + re-sync global tools
```

A first login runs it automatically (`.bashrc.user`), so a node you have never
touched sets itself up. `verify-node.sh` is the cheap, offline check for the
same assumptions and reinstates them if they are missing -- batch jobs call it
before doing any real work:

```bash
bash /lfs/local/0/$USER/verify-node.sh
```

Only these need to exist beforehand: system `git` and `curl`, and
`/dfs/user/$USER/.secrets/{wandb,huggingface,github}` (the one thing that is
shared rather than node-local; nothing here creates it).

Interactive extras, once per node:

```bash
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
fisher install IlanCosman/tide@v6
tide configure --auto --style=Lean --prompt_colors='True color' --show_time='12-hour format' --lean_prompt_height='Two lines' --prompt_connection=Dotted --prompt_connection_andor_frame_color=Lightest --prompt_spacing=Compact --icons='Many icons' --transient=No
curl -fsSL https://claude.ai/install.sh | bash
```
