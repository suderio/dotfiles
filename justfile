#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'
LOCAL_DIR := "$HOME/.local"
TMP_DIR := "$HOME/tmp"

default:
    @just --list
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
