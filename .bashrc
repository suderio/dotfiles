#!/bin/bash
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

HISTCONTROL=ignoreboth
export HISTIGNORE="&:ls:[bf]g:exit"
export HISTFILESIZE=20000
export HISTSIZE=10000
# Combine multiline commands into one in history
shopt -s cmdhist
# append to the history file, don't overwrite it
shopt -s histappend

shopt -s checkwinsize

if shopt -q globstar 2>/dev/null; then
  shopt -s globstar
fi

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

if [ -z "${chroot_ps1:-}" ] && [ -r /etc/chroot_ps1 ]; then
    chroot_ps1=$(cat /etc/chroot_ps1)
fi

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

force_color_prompt=yes
if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${chroot_ps1:+($chroot_ps1)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${chroot_ps1:+($chroot_ps1)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f /usr/bin/alacritty ]; then
  export TERMINAL=/usr/bin/alacritty
  export LC_ALL=pt_BR.UTF-8
fi

if [ -d $HOME/.bashrc.d ]; then
  for f in "$HOME"/.bashrc.d/*
  do
    source $f
  done
fi
[ -f "$HOME"/.shrc ] && source "$HOME"/.shrc

if [ -f ~/.aliases ]; then
    . ~/.aliases
fi

if [ -f $HOME/.jbang/bin/jbang ]; then
  alias j!=jbang
  export PATH="$HOME/.jbang/bin:$HOME/.jbang/currentjdk/bin:$PATH"
  export JAVA_HOME=$HOME/.jbang/currentjdk
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

eval "$(starship init bash)"

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

case ":$PATH:" in
    *:/home/paulo/.juliaup/bin:*)
        ;;

    *)
        export PATH=/home/paulo/.juliaup/bin${PATH:+:${PATH}}
        ;;
esac

# <<< juliaup initialize <<<
alias config='/usr/bin/git --git-dir=/home/paulo/repos/suderio/dotfiles/ --work-tree=/home/paulo'
