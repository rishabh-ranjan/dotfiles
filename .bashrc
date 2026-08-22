# vim: set ft=bash
#
# Only matters on machines where $HOME is this checkout directly and bash is
# the login shell (no /sailhome, no /lfs): hand over to fish via .bashrc.user.
# On the cluster that hand-off already happened in /sailhome/ranjanr/.bashrc
# before $HOME was moved here, so do nothing there -- otherwise a plain `bash`
# from fish would re-run setup-node.sh and exec straight back into fish.
[[ -d /lfs ]] && return
[[ -f ~/.bashrc.user ]] && . ~/.bashrc.user
