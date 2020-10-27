## export PS1="[\[\e[35m\]\A\[\e[m\]]\[\e[32m\]\w\[\e[m\]\\$ "
#export PS1="\[\e[33m\]\w\$\[\e[m\] "
#export CLICOLOR=1
#export LSCOLORS=ExFxBxDxCxegedabagacad
#alias ls='ls -GFh'
#alias py=python3
#alias python=python3
#alias nv='ssh nvidia@10.194.28.163'

source ~/.bashrc

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/zero/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/zero/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/zero/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/zero/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

