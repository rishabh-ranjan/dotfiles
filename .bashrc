# export PS1="[\[\e[35m\]\A\[\e[m\]]\[\e[32m\]\w\[\e[m\]\\$ "
# last to latest:
# export PS1="\[\e[36m\]\w\$\[\e[m\] \[\e[0m\]"
export PS1="\[\e[35m\][\t]\[\e[m\]\[\e[36m\]\w\\$\[\e[m\] "
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
alias ls='ls -GFh'
alias py=python3
alias python=python3
alias pip=pip3
alias nv='ssh -X nvidia@10.194.28.163'
# export PATH=/usr/local/jdk/bin:/usr/local/sbin:usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/root/bin
export PATH=/usr/local/bin:$PATH
export EDITOR='/usr/bin/env vim'
export NV=nvidia@10.194.28.163:/home/nvidia/Documents/catkin_ws/src
# sets vi mode for the bash command line
set -o vi

function tmx() {
	tmux new\; source-file ~/.tmux/sessions/"$1".conf
}

function cr() {
	set -o pipefail
	script -q /dev/null g++ -g -std=c++14 $1.cpp -o $1 2>&1 | head && echo '=== compiled ===' && ./$1
}

function crt() {
	set -o pipefail
	script -q /dev/null g++ -g -std=c++14 $1.cpp -o $1 2>&1 | head && echo '=== compiled ===' && ./$1 < $2
}
force_color_prompt=yes
export LC_ALL=en_US.UTF-8

# opam configuration
test -r /Users/zero/.opam/opam-init/init.sh && . /Users/zero/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true

alias valgrind='valgrind --track-origins=yes --dsymutil=yes'

# work-around for openMPI bug (see https://github.com/open-mpi/ompi/issues/7516)
export PMIX_MCA_gds=hash
# work-around for openMPI bug (see https://github.com/open-mpi/ompi/issues/6518)
export OMPI_MCA_btl=self,tcp
# allow many processes in openMPI
alias mpirun='mpirun --oversubscribe'

# load paths as a login shell would (added for go)
eval `/usr/libexec/path_helper -s`

# allow go programs to use all cores
export GOMAXPROCS=4

# compress prompt safely
alias prompt='export PS1="\[\e[36m\]\\$\[\e[m\] "'

# for llvm
export PATH="~/ss_project/llvm-10.0.0.src/build/bin:$PATH"

alias grep='grep -n --color=auto'

alias minisat='time cryptominisat5 --verb=0'
# alias minisat='/Users/zero/svs_proj/minisat-os-x/install/bin/minisat'

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
#__conda_setup="$('/Users/zero/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
#if [ $? -eq 0 ]; then
#    eval "$__conda_setup"
#else
#    if [ -f "/Users/zero/anaconda3/etc/profile.d/conda.sh" ]; then
#        . "/Users/zero/anaconda3/etc/profile.d/conda.sh"
#    else
#        export PATH="/Users/zero/anaconda3/bin:$PATH"
#    fi
#fi
#unset __conda_setup
# <<< conda initialize <<<

