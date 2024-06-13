#!/bin/bash
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '
##
##
##

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

# Add some paths
if [ -d "$HOME/.local/share/gem/ruby/3.0.0/bin" ]; then
    export PATH=$HOME/.local/share/gem/ruby/3.0.0/bin:$PATH
fi

# set PATH to include cargo
if [ -d "$HOME/.cargo/bin" ] ; then
    PATH="$HOME/.cargo/bin:$PATH"
fi

# set PATH to include go
if [ -d "$HOME/go/bin" ] ; then
    PATH="$HOME/go/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# add some custom or local configs
if [ -d "$HOME/bin/custom" ] ; then
    source $HOME/bin/custom
fi

if [ -d "$HOME/.shrc.d" ] ; then
    for f in $HOME/.shrc.d/*
    do
        source $f
    done
fi
# TODO add run everything in bashrc.d
# ex. function, aliases, custom, prompt

# Use neovim as vim

if [ -x "$(command -v nvim)" ] ; then
    alias vim='nvim'
fi

# User specific aliases and functions
alias lsd="ls -alF | grep /$"
alias ll="ls -l"

## pass options to free ## 
alias meminfo='free -m -l -t'
 
## get top process eating memory
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
 
## get top process eating cpu ##
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
 
## Get server cpu info ##
alias cpuinfo='lscpu'
 
## get GPU ram on desktop / laptop## 
alias gpumeminfo='grep -i --color memory /var/log/Xorg.0.log'


# This is GOLD for finding out what is taking so much space on your drives!
alias diskspace="du -S | sort -n -r |more"

# Some docker shit
alias dockrrmi='docker images | grep '\''<none>'\'' | grep -P '\''[1234567890abcdef]{12}'\'' -o | xargs -L1 docker rmi'
alias dockrrm='docker ps -a | grep -v '\''CONTAINER\|_config\|_data\|_run'\'' | cut -c-12 | xargs docker rm'
alias dockerm='docker rm -v $(docker ps -a -q -f status=exited)'
alias dockermi='docker rmi $(docker images -f "dangling=true" -q)'
alias dockermv='docker volume rm $(docker volume ls -qf dangling=true)'

# cd and ls
alias lcd=changeDirectory
function changeDirectory {
  cd $1 ; ls -la
}

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Always recover a session named $USER
alias restmux='[[ -z "$TMUX" ]] && exec tmux new-session -A -s $USER'

# Remember to run this now and then
alias scan='sudo freshclam && sudo clamscan -roi --exclude-dir="^/sys" '

# This is too hard to remember
alias show-dependencies='pacman -Qe | cut -d" " -f 1 | while read in; do pactree -r "$in"; done'

# Google drive sync
google_drive() {
  mount | grep "${HOME}/gdrive" >/dev/null || /usr/bin/google-drive-ocamlfuse "${HOME}/gdrive"
}

# Just to annoy people
test_iso_2022_locking_scape() {
  echo -e "\033(0"
}

# Extract everything without man pages
extract () {
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvjf $1    ;;
           *.tar.gz)    tar xvzf $1    ;;
           *.bz2)       bunzip2 $1     ;;
           *.rar)       unrar x $1       ;;
           *.gz)        gunzip $1      ;;
           *.tar)       tar xvf $1     ;;
           *.tbz2)      tar xvjf $1    ;;
           *.tgz)       tar xvzf $1    ;;
           *.zip)       unzip $1       ;;
           *.Z)         uncompress $1  ;;
           *.7z)        7z x $1        ;;
           *)           echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
}
