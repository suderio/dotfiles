#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'
LOCAL_DIR := "$HOME/.local"
TMP_DIR := "$HOME/tmp"

# Just list tasks
default:
  @just --list --unsorted | more

# Deletes tmp dir
[group('main')]
clean:
  rm -rf "{{TMP_DIR}}"/*

# Basic os packages for arch
[unix]
[group('main')]
base-arch: clean
    sudo pacman -Syu
    sudo pacman -S base-devel less man-db xclip sudo openssh pacman-contrib nasm zip unzip
    # Install paru
    git clone https://aur.archlinux.org/paru.git {{TMP_DIR}}
    makepkg -si

# Basic os packages for debian
[unix]
[group('main')]
base-deb:
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y openssh-server build-essential autoconf automake flex bison debian-keyring gettext gnu-standards re2c pkg-config libreadline-dev unzip zip libzstd-dev libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libgd-dev libonig-dev libzip-dev zlib1g-dev libffi-dev libyaml-dev xclip

# Dotfiles
[group('main')]
dotfiles:
    git clone --bare git@github.com:suderio/dotfiles "$HOME/.local/dotfiles"
    git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" config --local status.showUntrackedFiles no
    git --git-dir="$HOME"/.local/dotfiles/ --work-tree="$HOME" checkout

# Mise install
[unix]
[group('mise')]
mise:
    curl https://mise.run | sh

# Emacs install in arch
[unix]
[group('emacs')]
emacs-arch: && doom
    sudo pacman -S emacs-wayland

# Emacs install in debian
[unix]
[group('emacs')]
emacs-deb: && emacs-src doom
    sudo apt-get build-dep emacs

[private]
emacs-src: clean
    git clone https://git.savannah.gnu.org/git/emacs.git/ {{TMP_DIR}}
    git checkout emacs-30.2
    ./autogen.sh
    ./configure --prefix=/home/psude/.local --with-x-toolkit=gtk3 --with-mailutils --with-tree-sitter --with-pgtk --with-native-compilation=aot
    make clean
    make -j8
    make install

# Doom install
[unix]
[group('emacs')]
doom:
    git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
    ~/.config/emacs/bin/doom install

NERD_FONTS_URL := "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/"
FONTS := "FiraCode Noto NerdFontsSymbolsOnly" # DejaVuSansMono JetBrainsMono SourceCodePro
# Nerd Fonts install
[unix]
[group('other')]
install-fonts:
    for font in {{FONTS}}; do \
      just install-font $font; \
    done
    fc-cache -v

# Font install
[unix]
[group('other')]
install-font font:
    mkdir -p "$XDG_DATA_HOME/fonts/{{font}}"
    curl -sL "{{NERD_FONTS_URL}}{{font}}.tar.xz" | unxz | tar -xvf - -C "$XDG_DATA_HOME/fonts/{{font}}"
    chmod -R "u=rwx,g=r,o=r" "$XDG_DATA_HOME/fonts/{{font}}"

## lsps

[unix]
[group('lem')]
install-qlot:
  curl -fsSL https://qlot.tech/installer | sh
  ln -s "$HOME/.local/share/qlot/bin/qlot" "$HOME/.local/bin/qlot"

[unix]
[group('lem')]
install-lem-deps:
  paru -S sdl2 sdl2_image sdl2_ttf

[unix]
[group('lem')]
install-lem:
  git clone https://github.com/lem-project/lem.git
  cd lem && PREFIX="$HOME/.local" make install
