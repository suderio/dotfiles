#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'
LOCAL_DIR := "$HOME/.local"
TMP_DIR := "$HOME/tmp"

# Just list tasks
default:
    @echo "using {{cache_directory()}} as The user-specific cache directory."
    @echo "using {{config_directory()}} as The user-specific configuration directory."
    @echo "using {{config_local_directory()}} as The local user-specific configuration directory."
    @echo "using {{data_directory()}} as The user-specific data directory."
    @echo "using {{data_local_directory()}} as The local user-specific data directory."
    @echo "using {{executable_directory()}} as The user-specific executable directory."
    @echo "using {{home_directory()}} as Home directory"
    @echo "using {{TMP_DIR}} as temp and working directory"
    @mkdir -p "{{TMP_DIR}}"
    @just --list --unsorted | more

# Deletes tmp dir
[group('main')]
clean:
  rm -rf "{{TMP_DIR}}"/*
  rm -rf "{{TMP_DIR}}"/.[!.]*
# Basic os packages for arch
[unix]
[group('main')]
base-arch: clean
    sudo pacman -Syu
    sudo pacman -S base-devel git less man-db xclip oniguruma openssh pacman-contrib plocate postgresql-libs nasm re2c zip unzip libxml2 libyaml libzip maim xorg-xwininfo xdotool
    # Install paru
    git clone https://aur.archlinux.org/paru.git {{TMP_DIR}}
    makepkg -si

# Basic os packages for debian
[unix]
[group('main')]
base-deb:
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y openssh-server build-essential autoconf automake flex bison debian-keyring gettext gnu-standards re2c pkg-config libreadline-dev unzip zip libzstd-dev libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libgd-dev libonig-dev libzip-dev zlib1g-dev libffi-dev libyaml-dev xclip xdotool libxml2-utils maim

# Dotfiles
[group('main')]
dotfiles:
    git clone --bare git@github.com:suderio/dotfiles "{{LOCAL_DIR}}/dotfiles"
    git --git-dir="{{LOCAL_DIR}}/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
    git --git-dir="{{LOCAL_DIR}}/dotfiles" --work-tree="$HOME" checkout

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
    ./configure --prefix={{LOCAL_DIR}} --with-x-toolkit=gtk3 --with-mailutils --with-tree-sitter --with-pgtk --with-native-compilation=aot
    make clean
    make -j8
    make install

# Doom install
[unix]
[group('emacs')]
doom:
    git clone --depth 1 https://github.com/doomemacs/doomemacs "{{config_directory()}}/emacs"
    {{config_directory()}}/emacs/bin/doom" install

NERD_FONTS_URL := "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/"
FONTS := "FiraCode Noto NerdFontsSymbolsOnly" # DejaVuSansMono JetBrainsMono SourceCodePro
# Nerd Fonts install
[unix]
[group('other')]
fonts:
    for font in {{FONTS}}; do \
      just install-font $font; \
    done
    fc-cache -v

# Font install
[unix]
[group('other')]
font font:
    mkdir -p "$XDG_DATA_HOME/fonts/{{font}}"
    curl -sL "{{NERD_FONTS_URL}}{{font}}.tar.xz" | unxz | tar -xvf - -C "$XDG_DATA_HOME/fonts/{{font}}"
    chmod -R "u=rwx,g=r,o=r" "$XDG_DATA_HOME/fonts/{{font}}"

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

# Hunspell install
[unix]
[group('spelling')]
hunspell: clean
  git clone https://github.com/hunspell/hunspell.git {{TMP_DIR}}
  autoreconf -vfi && ./configure --prefix={{LOCAL_DIR}} --with-readline && make && make install && sudo ldconfig

# Hunspell dictionaries
[unix]
[group('spelling')]
hunspell-dicts: clean
  curl -O https://hunspell.memoq.com/de.zip
  unzip -j "de.zip" "de/de_DE*" -d "{{data_directory()}}/hunspell/"
  curl -O https://hunspell.memoq.com/fr_FR.zip
  unzip -j "fr_FR.zip" "fr_FR/fr.*" -d "{{data_directory()}}/hunspell/"
  curl -O https://hunspell.memoq.com/it_IT.zip
  unzip -j "it_IT.zip" "it_IT/it_IT.*" -d "{{data_directory()}}/hunspell/"
  curl -O https://hunspell.memoq.com/pt_BR.zip
  unzip -j "pt_BR.zip" "pt_BR/pt_BR.*" -d "{{data_directory()}}/hunspell/"
  curl -O https://hunspell.memoq.com/es.zip
  unzip -j "es.zip" "es/es_ES.*" -d "{{data_directory()}}/hunspell/"
  curl -O https://hunspell.memoq.com/en.zip
  unzip -j "en.zip" "en/en_US.*" -d "{{data_directory()}}/hunspell/"

# Install Julia Language Server
[group('devtools')]
julia:
    julia -- "{{config_directory()}}/julia/emacs.jl"

# Graphviz (for org mode dot rendering)
[unix]
[group('devtools')]
graphviz: clean
  curl -fsSLO https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/14.0.2/graphviz-14.0.2.tar.gz
  tar -xvf graphviz-14.0.2.tar.gz
  cd graphviz-14.0.2 && ./configure --prefix={{LOCAL_DIR}} --enable-static && make && make install

# pynvim and npm neovim (for python/js in neovim)
[group('devtools')]
neovim:
  uv venv "{{data_directory()}}/nvim/venv"
  uv pip install pynvim -p "{{data_directory()}}/nvim/venv"
  npm install --global neovim

[group('devtools')]
tidy: clean
  git clone https://github.com/htacg/tidy-html5.git {{TMP_DIR}}
  cd build/cmake \
    && cmake ../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX={{LOCAL_DIR}} -DBUILD_SHARED_LIB:BOOL=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    && make \
    && make install

# install cljfmt
[group('devtools')]
clojure:
    curl -o cljfmt.tar.gz -sL "https://github.com/weavejester/cljfmt/releases/download/0.15.3/cljfmt-0.15.3-linux-amd64-static.tar.gz"
    tar -xzf cljfmt.tar.gz -C {{LOCAL_DIR}}/bin/

# Updates all - this will take some time
[unix]
[group('update')]
update:
    sudo pacman -Syu || sudo apt update && sudo apt upgrade -y
    config pull
    mise self-update
    mise upgrade
    cargo upgrade
    gup update
    uv tool upgrade --all
    npm update --global
    doom upgrade
    echo "cljfmt, tidy, paru cannot be automatically updated"

[group('diagnostic')]
doctor:
    mise doctor
    doom doctor

# TODO
#NPM_PACKAGES := "markdownlint @mermaid-js/mermaid-cli"
# https://github.com/fwcd/kotlin-language-server
# ver .config/emacs/.local/etc/lsp/kotlin-language-server*

# json, python, just treesitter
# ver .config/emacs/.local/etc/tree-sitter/libtree-sitter-just.so
