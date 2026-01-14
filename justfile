#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'
LOCAL_DIR := "$HOME/.local"
TMP_DIR := "$HOME/tmp"
NERD_FONTS_URL := "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/"
FONTS := "FiraCode Noto NerdFontsSymbolsOnly"
HUNSPELL_URL := "https://hunspell.memoq.com"
GRAPHVIZ_URL := "https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/14.0.2/graphviz-14.0.2.tar.gz"

default:
    @just --list
    @echo "LOCAL_DIR := {{LOCAL_DIR}}"
    @echo "TMP_DIR := {{TMP_DIR}}"
    @echo "DATA_LOCAL_DIRECTORY := {{data_local_directory()}}"
    @echo "DATA_DIRECTORY := {{data_directory()}}"
    @echo "CONFIG_LOCAL_DIRECTORY := {{config_local_directory()}}"
    @echo "CONFIG_DIRECTORY := {{config_directory()}}"
    @echo "BIN_DIRECTORY := {{executable_directory()}}"

clean:
    rm -rf "$TMP_DIR"/*
    rm -rf "$TMP_DIR"/.[!.]*

[group('main')]
dotfiles:
    git clone --bare git@github.com:suderio/dotfiles "{{LOCAL_DIR}}/dotfiles"
    git --git-dir="{{LOCAL_DIR}}/dotfiles" --work-tree="$HOME" config --local status.showUntrackedFiles no
    git --git-dir="{{LOCAL_DIR}}/dotfiles" --work-tree="$HOME" checkout

[unix]
[group('mise')]
mise:
    curl https://mise.run | sh

[unix]
[group('os')]
arch:
    sudo pacman -Syu
    sudo pacman -S base-devel git less man-db xclip oniguruma openssh \
          pacman-contrib plocate postgresql-libs nasm re2c zip unzip libxml2 \
          libyaml libzip maim xorg-xwininfo xdotool wget languagetool mpv gnuplot

[unix]
[group('os')]
paru:
    sudo pacman -Syu
    git clone https://aur.archlinux.org/paru.git
    cd paru && makepkg -si

[unix]
[group('os')]
debian:
    # languagetool is missing
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y openssh-server build-essential autoconf automake flex \
         bison debian-keyring gettext gnu-standards re2c pkg-config \
         libreadline-dev unzip zip libzstd-dev libxml2-dev libssl-dev \
         libsqlite3-dev libcurl4-openssl-dev libgd-dev libonig-dev libzip-dev \
         zlib1g-dev libffi-dev libyaml-dev xclip xdotool libxml2-utils maim wget \
         mpv gnuplot

[unix]
[group('emacs')]
emacs_arch:
    sudo pacman -S emacs-wayland

[unix]
[group('emacs')]
emacs_debian: && emacs_src
    sudo apt-get build-dep emacs
    @just emacs_src

[group('emacs')]
emacs_src: clean
    git clone https://git.savannah.gnu.org/git/emacs.git/ "{{TMP_DIR}}"
    git checkout emacs-30.2
    ./autogen.sh
    ./configure --prefix=$LOCAL_DIR --with-x-toolkit=gtk3 --with-mailutils \
                --with-tree-sitter --with-pgtk --with-native-compilation=aot
    make clean
    make -j8
    make install

[group('emacs')]
doom:
    git clone --depth 1 https://github.com/doomemacs/doomemacs "{{config_local_directory()}}/emacs"
    "{{config_local_directory()}}/emacs/bin/doom" install --no-config --env --install --force

[script]
[group('emacs')]
fonts:
    for font in {{FONTS}}; do
    mkdir -p {{data_local_directory()}}/fonts/$font
        curl -sL "{{NERD_FONTS_URL}}$font.tar.xz" | unxz | tar -xvf - -C {{data_local_directory()}}/fonts/$font
        chmod -R "u=rwx,g=r,o=r" {{data_local_directory()}}/fonts/$font
    done
    fc-cache -v

[group('emacs')]
hunspell: clean
    git clone https://github.com/hunspell/hunspell.git {{TMP_DIR}}
    autoreconf -vfi
    cp ../ltmain.sh ./
    ./configure --prefix=$LOCAL_DIR --with-readline
    make
    make install
    sudo ldconfig

[group('emacs')]
hunspell-dicts: clean
    curl -O $HUNSPELL_URL/de.zip
    unzip -j "de.zip" "de/de_DE*" -d "{{data_local_directory()}}/hunspell/"
    curl -O $HUNSPELL_URL/fr_FR.zip
    unzip -j "fr_FR.zip" "fr_FR/fr.*" -d "{{data_local_directory()}}/hunspell/"
    curl -O $HUNSPELL_URL/it_IT.zip
    unzip -j "it_IT.zip" "it_IT/it_IT.*" -d "{{data_local_directory()}}/hunspell/"
    curl -O $HUNSPELL_URL/pt_BR.zip
    unzip -j "pt_BR.zip" "pt_BR/pt_BR.*" -d "{{data_local_directory()}}/hunspell/"
    curl -O $HUNSPELL_URL/es.zip
    unzip -j "es.zip" "es/es_ES.*" -d "{{data_local_directory()}}/hunspell/"
    curl -O $HUNSPELL_URL/en.zip
    unzip -j "en.zip" "en/en_US.*" -d "{{data_local_directory()}}/hunspell/"

[unix]
[group('emacs')]
[script]
graphviz: clean
    curl -o graphviz.tar.gz -fsSL {{GRAPHVIZ_URL}}
    tar -xvf graphviz.tar.gz
    cd graphviz-14.0.2
    ./configure --prefix=$LOCAL_DIR --enable-static
    make
    make install

[group('neovim')]
[script]
pynvim:
    uv venv "{{data_local_directory()}}/nvim/venv"
    uv pip install pynvim -p "{{data_local_directory()}}/nvim/venv"

[group('neovim')]
npm_neovim:
    npm install --global neovim

[group('neovim')]
gem_neovim:
    gem install neovim

[unix]
[group('emacs')]
[script]
tidy: clean
    git clone https://github.com/htacg/tidy-html5.git {{TMP_DIR}}
    cd build/cmake
    cmake ../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX={{LOCAL_DIR}} -DBUILD_SHARED_LIB:BOOL=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    make
    make install

[group('emacs')]
clojure: clean
    curl -o cljfmt.tar.gz -sL "https://github.com/weavejester/cljfmt/releases/download/0.15.3/cljfmt-0.15.3-linux-amd64-static.tar.gz"
    tar -xzf cljfmt.tar.gz -C {{executable_directory()}}
    curl -fsSLO https://raw.githubusercontent.com/clojure-lsp/clojure-lsp/master/install
    chmod u+x install
    ./install --dir "{{executable_directory()}}"
