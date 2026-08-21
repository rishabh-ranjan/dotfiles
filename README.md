# dotfiles

The node-local home (`/lfs/local/0/$USER`) is a checkout of this repo plus its
own pixi install. `setup-node.sh` creates both and is idempotent, so setting up
a node, updating one, and checking one are the same command:

```bash
curl -fsSL https://raw.githubusercontent.com/rishabh-ranjan/dotfiles/main/setup-node.sh | bash
bash ~/setup-node.sh --update   # pull dotfiles + re-sync global tools
```

A first login runs it automatically (`.bashrc.user`), so a node you have never
touched sets itself up. Without `--update` the same script is the check batch
jobs run before doing any real work: a few stat calls and no network on a
healthy node, a full setup on a bare one, non-zero exit if the node cannot be
brought up to spec.

```bash
bash /lfs/local/0/$USER/setup-node.sh
```

Only these need to exist beforehand: system `git` and `curl`, and
`/dfs/user/$USER/.secrets/{wandb,huggingface,github}` (the one thing that is
shared rather than node-local; nothing here creates it).

Interactive extras, once per node:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

The fish prompt needs nothing manual: `.config/fish/conf.d/tide_setup.fish`
bootstraps fisher, installs the plugins in `.config/fish/fish_plugins`, and
applies the tide configuration on first interactive shell. To change the
prompt, edit the `tide configure` flags there and bump `TIDE_CONFIG_VERSION`.
