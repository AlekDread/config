# .bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='\[\e[32m\]\W\[\e[0m\] > '

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx
fi

# Use bash-completion, if available, and avoid double-sourcing
[[ $PS1 &&
  ! ${BASH_COMPLETION_VERSINFO:-} &&
  -f /usr/share/bash-completion/bash_completion ]] &&
  . /usr/share/bash-completion/bash_completion

export XDG_RUNTIME_DIR=/run/user/$(id -u)
export QT_QPA_PLATFORMTHEME=qt5ct

# Основные алиасы (минимально)
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias grep='grep --color=auto'

alias sudo='doas'
complete -F _command doas
