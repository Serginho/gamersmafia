if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

function parse_git_branch {
  local branch=$(__git_ps1 "%s")
  [[ $branch ]] && echo "[$branch]"
}

export EDITOR=vim
export HISTCONTROL=erasedups
export HISTSIZE=50000
export HISTTIMEFORMAT="%Y%m%d %H:%M:%S "
# export PS1="\[\033[1;30m\]$(date +%H:%M:%S) \[\033[0;33m\]\w\[\033[0m\]\[\033[1;30m\]$(parse_git_branch)$\[\033[0m\] "
export PS1='\[\033[1;33m\]$(date +%H:%M:%S) \w\[\033[1;30m\]$(parse_git_branch)$ \[\033[0m\]'

shopt -s histappend

alias ls='ls -ApG --color=auto'
alias ll='ls -l'
alias rtest="ruby -Itest"
