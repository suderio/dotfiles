git clone --bare git@github.com:suderio/dotfiles "$HOME/.local/dotfiles"
git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" config --local status.showUntrackedFiles no
git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" checkout

curl https://mise.run | sh
mise up

mise tasks ls
