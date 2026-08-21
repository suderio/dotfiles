git clone --bare git@github.com:suderio/dotfiles "$HOME/.local/dotfiles"
git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" config --local status.showUntrackedFiles no
git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" checkout

curl -fsSL https://mise.run -o install-mise.sh
chmod +x install-mise.sh
./install-mise.sh
rm install-mise.sh
mise up

mise tasks ls
