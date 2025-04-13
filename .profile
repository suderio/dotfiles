export AMD_VULKAN_ICD=RADV
export BROWSER=firedragon
export EDITOR=vim
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export MAIL=thunderbird
export TERM=xterm
export VISUAL=emacs

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="${HOME}/.cache"
export XDG_DATA_HOME="${HOME}/.local/share"
export XDG_STATE_HOME="${HOME}/.local/state"

export NVM_DIR="$HOME/.config/nvm"
export SDKMAN_DIR="$HOME/.sdkman"

[ -d "$HOME/.cargo/bin" ] && PATH="$HOME/.cargo/bin:$PATH"
[ -d "$HOME/go/bin" ] && PATH="$HOME/go/bin:$PATH"
[ -d "$HOME/.config/emacs/bin" ] && PATH="$HOME/.config/emacs/bin:$PATH"
[ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.juliaup/bin" ] && PATH="$HOME/.juliaup/bin:$PATH"
[ -d "$HOME/perl5/bin" ] && PATH="$HOME/perl5/bin:${PATH}"

export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"
export PERL_LOCAL_LIB_ROOT="$HOME/perl5${PERL_LOCAL_LIB_ROOT:+:${PERL_LOCAL_LIB_ROOT}}"
export PERL_MB_OPT="--install_base \"$HOME/perl5\""
export PERL_MM_OPT="INSTALL_BASE=$HOME/perl5"
export MANPATH="$HOME/perl5/man:$MANPATH"


export PATH
