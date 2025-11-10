#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'
LOCAL_DIR := "$HOME/.local"
TMP_DIR := "$HOME/tmp"

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
