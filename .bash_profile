#
# ~/.bash_profile
#
# Fast exit and simple prompt for Emacs TRAMP
if [ "$TERM" = "dumb" ]; then
    unsetopt zle prompt_cr prompt_subst 2>/dev/null # For Zsh compatibility
    PS1='$ '
    return
fi

[[ -f "$HOME/.profile" ]] && . "$HOME/.profile"
[[ -f "$HOME/.bashrc" ]] && . "$HOME/.bashrc"
