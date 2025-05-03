alias config='git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME"'

git clone --bare git@github.com:suderio/dotfiles $HOME/.local/dotfiles
config config --local status.showUntrackedFiles no
config checkout

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
cargo install just

mkdir -p "$HOME/tmp"
