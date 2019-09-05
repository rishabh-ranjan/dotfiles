# export PS1="[\[\e[35m\]\A\[\e[m\]]\[\e[32m\]\w\[\e[m\]\\$ "
export PS1="\[\e[36m\]\w\$\[\e[m\] \[\e[37m\]"
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
	script -q /dev/null g++ -std=c++14 $1.cpp -o $1 2>&1 | head && echo '=== compiled ===' && ./$1
}

function crt() {
	set -o pipefail
	script -q /dev/null g++ -std=c++14 $1.cpp -o $1 2>&1 | head && echo '=== compiled ===' && ./$1 < $2
}

