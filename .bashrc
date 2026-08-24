# vim: set ft=bash
#
# Only matters on machines where $HOME is this checkout directly and bash is
# the login shell (no /sailhome, no /lfs): hand over to fish via .bashrc.user.
# On the cluster, /sailhome/ranjanr is this same checkout: the hand-off runs
# from here on the first (HOME=/sailhome) pass and must not run again once
# $HOME has moved to /lfs -- otherwise a plain `bash` from fish would re-run
# setup-node.sh and exec straight back into fish. Guard on $HOME, not on /lfs
# existing: `ssh <node> cmd` starts with HOME=/sailhome and needs the hand-off
# (pixi on PATH, HOME moved) just like a login does.
[[ -d /lfs && $HOME == /lfs/* ]] && return
[[ -f ~/.bashrc.user ]] && . ~/.bashrc.user
