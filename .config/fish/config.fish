set fish_greeting

fish_vi_key_bindings
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_visual underscore

set -x EDITOR nvim
set -x VISUAL nvim
set -x LANG en_US.UTF-8
set -x LANGUAGE en_US.UTF-8
set -x LC_ALL en_US.UTF-8

set -x PYTHONPATH "$HOME/.config/python"

set -x WANDB_DIR "$HOME/.cache/"
set -x WANDB_CONSOLE "off"

set -x GH_TOKEN (cat /sailhome/ranjanr/.secrets/github)
set -x GITHUB_TOKEN $GH_TOKEN
set -x HF_TOKEN (cat /sailhome/ranjanr/.secrets/huggingface)
set -x WANDB_API_KEY (cat /sailhome/ranjanr/.secrets/wandb)

fish_add_path --path "/sailhome/ranjanr/.local/bin"
fish_add_path --path "/sailhome/ranjanr/.pixi/bin"
fish_add_path --path "$HOME/.local/bin"
fish_add_path --path "$HOME/.pixi/bin"
