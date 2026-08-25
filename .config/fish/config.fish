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

# ~/scratch is the cluster's shared store (setup-node.sh); absent on the mac,
# hence the guard. Tokens are the one thing that must not be node-local.
# Interactive shells export them; batch jobs read the files themselves rather
# than inheriting the submitting env.
set -l secrets $HOME/scratch/.secrets
if test -d $secrets
	set -x GH_TOKEN (cat $secrets/github)
	set -x GITHUB_TOKEN $GH_TOKEN
	set -x HF_TOKEN (cat $secrets/huggingface)
	set -x HUGGING_FACE_HUB_TOKEN $HF_TOKEN
	set -x WANDB_API_KEY (cat $secrets/wandb)
	set -x PYPI_API_TOKEN (cat $secrets/pypi)
	set -x UV_PUBLISH_TOKEN $PYPI_API_TOKEN
	set -x TWINE_USERNAME __token__
	set -x TWINE_PASSWORD $PYPI_API_TOKEN
end

# Kerberos: stanford.edu realm (FarmShare) — system krb5.conf has stale KDCs
set -gx KRB5_CONFIG /afs/cs.stanford.edu/u/ranjanr/.krb5.conf
