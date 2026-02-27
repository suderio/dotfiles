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

shopt -q globstar 2>/dev/null && shopt -s globstar

command -v lesspipe &>/dev/null && eval "$(SHELL=/bin/sh lesspipe)"

[ -z "${chroot_ps1:-}" ] && [ -r /etc/chroot_ps1 ] && chroot_ps1=$(cat /etc/chroot_ps1)

case "$TERM" in
    xterm-color | *-256color) color_prompt=yes ;;
esac

force_color_prompt=yes
# We have color support; assume it's compliant with Ecma-48
# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
# a case would tend to support setf rather than setaf.)

[ -n "$force_color_prompt" ] && command -v tput &>/dev/null && (tput setaf || tput AF) &>/dev/null && color_prompt=yes || color_prompt=
[ "$color_prompt" = yes ] &&
    PS1='${chroot_ps1:+($chroot_ps1)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ ' ||
    PS1='${chroot_ps1:+($chroot_ps1)}\u@\h:\w\$ '
unset color_prompt force_color_prompt

export LESS=-R
export LESS_TERMCAP_mb=$'\E[1;31m'     # begin blink
export LESS_TERMCAP_md=$'\E[1;36m'     # begin bold
export LESS_TERMCAP_me=$'\E[0m'        # reset bold/blink
export LESS_TERMCAP_so=$'\E[01;44;33m' # begin reverse video
export LESS_TERMCAP_se=$'\E[0m'        # reset reverse video
export LESS_TERMCAP_us=$'\E[1;32m'     # begin underline
export LESS_TERMCAP_ue=$'\E[0m'        # reset underline

export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# this is to avoid testing for every file
sud_source() {
    [ -s "$1" ] && . "$1"
}

[ -f "$HOME/.local/bin/mise" ] && eval "$("$HOME/.local/bin/mise" activate bash)"

sud_source "$HOME/.profile"

[ -d "$HOME"/.bashrc.d ] && for f in "$HOME"/.bashrc.d/*; do source "$f"; done

[ -n "$SSH_AUTH_SOCK" ] || echo "ssh-agent is not running or not accessible. Starting a new one..." && eval "$(ssh-agent -s)" &>/dev/null && ssh-add "$HOME/.ssh/id_ed25519" &>/dev/null

command -v starship &>/dev/null && eval -- "$(starship init bash --print-full-init)"

# TODO Corrigir essa configuração do ruby!
[ -x "$HOME/.rbenv/bin/rbenv" ] && eval "$(~/.rbenv/bin/rbenv init - --no-rehash bash)"

command -v perl &>/dev/null && [ -d "$HOME/perl5/lib/perl5" ] && eval "$(perl -I ~/perl5/lib/perl5 -Mlocal::lib)" &>/dev/null

command -v fzf &>/dev/null && eval "$(fzf --bash)"

sud_source "$NVM_DIR/nvm.sh"
sud_source "$NVM_DIR/bash_completion"
sud_source "$HOME/.cargo/env"
sud_source "$HOME/.sdkman/bin/sdkman-init.sh"
sud_source "$HOME/.ghcup/env"
sud_source "/usr/share/doc/pkgfile/command-not-found.bash"
