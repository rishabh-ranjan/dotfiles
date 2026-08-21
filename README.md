# dotfiles

Node-local home (`/lfs/local/0/$USER`) = this repo + its own pixi. `setup-node.sh` is idempotent: setup, update, and check are the same command. First login runs it automatically (`.bashrc.user`).

```bash
curl -fsSL https://raw.githubusercontent.com/rishabh-ranjan/dotfiles/main/setup-node.sh | bash
bash ~/setup-node.sh --update   # pull dotfiles + re-sync global tools
bash /lfs/local/0/$USER/setup-node.sh   # check before batch jobs
```

Needs: system `git`, `curl`, and `/dfs/user/$USER/.secrets/{wandb,huggingface,github}`.

Once per node: `curl -fsSL https://claude.ai/install.sh | bash`

Fish prompt: `.config/fish/conf.d/tide_setup.fish` installs fisher, `fish_plugins`, and the tide config on first shell. Edit flags there and bump `TIDE_CONFIG_VERSION` to re-apply.
