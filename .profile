export AMD_VULKAN_ICD=RADV
export BROWSER=firedragon
export EDITOR=vim
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export MAIL=thunderbird
export TERM=xterm
export VISUAL=emacs

# >>> juliaup initialize >>>

# !! Contents within this block are managed by juliaup !!

case ":$PATH:" in
*:/home/paulo/.juliaup/bin:*) ;;

*)
  export PATH=/home/paulo/.juliaup/bin${PATH:+:${PATH}}
  ;;
esac

# <<< juliaup initialize <<<
