#!/usr/bin/env just --justfile

set working-directory := 'tmp'
set tempdir := 'tmp'

# Lista de linguagens/pacotes desejados
OS_PACKAGES := "cmake mpv sxiv jq zip unzip git less curl wget shellcheck file gnupg openssh base-devel xdg-user-dirs xdg-utils php bash-completion"
RUST_PACKAGES := "bat eza git-delta bvaisvil/zenith.git du-dust tree-sitter-cli viu fd-find procs ast-grep starship zellij nu ripgrep "
PYTHON_PACKAGES := "isort pipenv nose nose2 pytest pylatexenc black pyflakes"
RUBY_PACKAGES := "neovim"
RUBY_PACKAGES_NOT_USED := "chef-utils concurrent kramdown kramdown-parser-gfm mixlib-cli mixlib-config mixlib-shellout rexml ruby-tomlrb"
GO_PACKAGES := "github.com/jesseduffield/lazygit@latest github.com/fatih/gomodifytags@latest github.com/cweill/gotests/gotests@latest golang.org/x/tools/gopls@latest mvdan.cc/sh/v3/cmd/shfmt@latest github.com/x-motemen/gore/cmd/gore@latest github.com/jessfraz/dockfmt@latest"
NPM_PACKAGES := "prettier bash-language-server node-gyp semver stylelint neovim  js-beautify markdownlint @mermaid-js/mermaid-cli"
PERL_PACKAGES := "Neovim::Ext Time::Piece"
MAKE_PACKAGES := "fzf neovim go lua luarocks texlive pandoc pynvim"
FONTS := "FiraCode DejaVuSansMono JetBrainsMono SourceCodePro Noto NerdFontsSymbolsOnly"
OTHER_PACKAGES := "setuptools lynis clamav emacs-wayland github-cli zathura zathura-djvu zathura-ps zathura-cb xdotool lua51 kitty ghostty imagemagick sbcl"
DUNO := "xclip aria2 aspell biber direnv git-lfs gnuplot pass sshfs chafa ueberzugpp zig zshdb shfmt tidy zls bashdb"
PACKAGES_UNINSTALL := "python-pynvim texlive pandoc markdownlint ruby-mixlib-shellout ruby-chef-utils ruby-concurrent ruby-kramdown-parser-gfm ruby-kramdown ruby-mixlib-cli ruby-mixlib-config ruby-rexml ruby-tomlrb lazygit npm bash-language-server node-gyp nodejs-nopt prettier semver stylelint nodejs bat eza ripgrep git-delta zenith dust tree-sitter-cli viu fd procs rustup ruby composer jdk-openjdk kotlin ktlint cpanminus julia gopls python-pipx python-isort python-nose python-nose2 python-pipenv python-pylatexenc python-pytest"

LOCAL_DIR := "$HOME/.local"
LUA_VERSION := "5.4.7"
LUAROCKS_VERSION := "3.11.1"
GO_VERSION := "1.24.2"
NERD_FONTS_URL := "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/"
NVM_INSTALL_URL := "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh"
KTLINT_INSTALL_URL := "https://github.com/pinterest/ktlint/releases/download/1.5.0/ktlint"
NEOVIM_INSTALL_URL := "https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz"
LUA_INSTALL_URL := "https://www.lua.org/ftp/lua-5.4.7.tar.gz"
LUAROCKS_INSTALL_URL := "https://luarocks.github.io/luarocks/releases/luarocks-3.11.1.tar.gz"
GO_INSTALL_URL := "https://go.dev/dl/go1.24.2.linux-amd64.tar.gz"

alias ios := install-os-packages
alias igo := install-go-packages
alias inpm := install-npm-packages
alias irust := install-rust-packages
alias ipython := install-python-packages
alias iperl := install-perl-packages
alias igem := install-gem-packages
alias ifonts := install-fonts
alias ros := remove-os-packages
alias i := install
alias c := clean

default:
  @just --list | more

[unix]
[group('main')]
check:
    @for p in clang cmake emacs git less ninja ssh cabal sudo unzip vim lua wget zip go cargo starship ruby php fzf java nvim; do command -v "$p" >/dev/null 2>&1 || echo "No $p!"; done
    @for p in bat eza delta dot zenith dust fd procs zellij rg uv lazygit pandoc tex magick sbcl zig tidy doom; do command -v "$p" >/dev/null 2>&1 || echo "Missing $p."; done

[unix]
[group('main')]
install:
  echo {{ cache_directory() }}
  echo {{ config_directory() }}
  echo {{ config_local_directory() }}
  echo {{ data_directory() }}
  echo {{ data_local_directory() }}
  echo {{ executable_directory() }}
  echo {{ home_directory() }}

[unix]
[group('main')]
clean:
  rm -rf "$HOME/tmp"/*

# Instala algumas Nerd Fonts
[unix]
[group('base')]
install-fonts:
  for font in {{FONTS}}; do \
    just install-font $font; \
  done
  fc-cache -v

[unix]
[group('aux')]
install-font font:
    mkdir -p "$XDG_DATA_HOME/fonts/{{font}}"
    curl -sL "{{NERD_FONTS_URL}}{{font}}.tar.xz" | unxz | tar -xvf - -C "$XDG_DATA_HOME/fonts/{{font}}"
    chmod -R "u=rwx,g=r,o=r" "$XDG_DATA_HOME/fonts/{{font}}"

[unix]
[group('base')]
install-nvm:
  mkdir -p "$NVM_DIR"
  [ -s "$NVM_DIR/nvm.sh" ] || bash -c 'curl -o- {{NVM_INSTALL_URL}} | bash'
  source "$NVM_DIR/nvm.sh" && nvm install node

[unix]
[group('base')]
install-rustup:
  command -v cargo >/dev/null 2>&1 || curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

[group('base')]
install-python:
  cargo install --git https://github.com/astral-sh/uv uv
  uv python install --preview

[group('base')]
install-rbenv:
  # ruby rubygems
  curl -fsSL https://rbenv.org/install.sh | bash
  # TODO recuperar a última versão do install -l
  "$HOME/.rbenv/bin/rbenv" install -l
  "$HOME/.rbenv/bin/rbenv" install 3.4.4
  "$HOME/.rbenv/bin/rbenv" global 3.4.4

[group('base')]
install-composer:
  #!/usr/bin/env bash
  # composer TODO PHP
  EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

  if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
  then
      >&2 echo 'ERROR: Invalid installer checksum'
      rm composer-setup.php
      exit 1
  fi

  php composer-setup.php --quiet --install-dir="$HOME/.local/bin" --filename=composer
  RESULT=$?
  rm composer-setup.php

[group('base')]
install-sdkman:
  curl -s "https://get.sdkman.io" | bash
  . "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install java
  . "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install kotlin
  curl -sSLO {{KTLINT_INSTALL_URL}} && chmod a+x ktlint && mv ktlint "$HOME/.local/bin/"

[group('base')]
install-julia:
  curl -fsSL https://install.julialang.org | sh

[group('base')]
install-cpan:
  cpan
  curl http://cpanmin.us | perl - -l ~/perl5 App::cpanminus local::lib

[group('base')]
install-lua:
  curl -fsSLRO {{LUA_INSTALL_URL}}
  tar zxf lua-{{LUA_VERSION}}.tar.gz
  cd lua-{{LUA_VERSION}} && make all test
  cd lua-{{LUA_VERSION}} && make install INSTALL_TOP={{LOCAL_DIR}}
  curl -fsSLRO {{LUAROCKS_INSTALL_URL}}
  tar zxf luarocks-{{LUAROCKS_VERSION}}.tar.gz
  cd luarocks-{{LUAROCKS_VERSION}} && ./configure --prefix={{LOCAL_DIR}} --with-lua="$HOME/.local"
  cd luarocks-{{LUAROCKS_VERSION}} && make
  cd luarocks-{{LUAROCKS_VERSION}} && make install
  rm -rf lua-{{LUA_VERSION}}.tar.gz lua-{{LUA_VERSION}} luarocks-{{LUAROCKS_VERSION}}.tar.gz luarocks-{{LUAROCKS_VERSION}}

[group('base')]
install-go:
  curl -fsSLRO {{GO_INSTALL_URL}}
  tar -xvf go{{GO_VERSION}}.linux-amd64.tar.gz
  mv go "{{LOCAL_DIR}}/"

[group('uninstall')]
uninstall-go:
  rm -rf "{{LOCAL_DIR}}/go"

[group('base')]
install-sbcl:
  curl -fsSLo sbcl.tar.bz2 http://prdownloads.sourceforge.net/sbcl/sbcl-2.5.3-x86-64-linux-binary.tar.bz2
  bzip2 -cd sbcl.tar.bz2 | tar xvf -
  cd sbcl-2.5.3-x86-64-linux && INSTALL_ROOT={{LOCAL_DIR}} sh install.sh
 
[group('base')]
install-zig:
  curl -fsSLo zig.tar.xz https://ziglang.org/download/0.14.0/zig-linux-x86_64-0.14.0.tar.xz
  tar -xvf zig.tar.xz
  mv zig-linux-x86_64*/zig "$HOME/.local/bin/"
  mv zig-linux-x86_64*/lib "$HOME/.local/lib/zig"

[group('base')]
install-cmake:
  curl -fsSLo cmake.sh https://github.com/Kitware/CMake/releases/download/v4.0.2/cmake-4.0.2-linux-x86_64.sh
  chmod u+x cmake.sh
  ./cmake.sh --prefix={{LOCAL_DIR}} --skip-license

[group('base')]
install-ninja:
  git clone https://github.com/ninja-build/ninja.git
  cd ninja && git checkout release
  cd ninja && ./configure.py --bootstrap
  cp ninja/ninja "$HOME/.local/bin/"

[group('base')]
install-fzf:
  git clone https://github.com/junegunn/fzf.git
  cd fzf && ./install --bin
  cp fzf/bin/* "$HOME/.local/bin/"

[group('base')]
install-cabal:
  curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh

[group('lem')]
install-qlot:
  curl -fsSL https://qlot.tech/installer | sh
  ln -s "$HOME/.local/share/qlot/bin/qlot" "$HOME/.local/bin/qlot"

[group('lem')]
install-lem-deps:
  sudo pacman -S sdl2_image sdl2_ttf

[group('lem')]
install-lem:
  git clone https://github.com/lem-project/lem.git
  cd lem && PREFIX="$HOME/.local" make install

[group('app')]
install-jq:
  curl -fsSLo jq https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-linux-amd64
  chmod u+x jq
  mv jq "$HOME/.local/bin/"

[group('app')]
install-graphviz:
  curl -fsSLO https://gitlab.com/api/v4/projects/4207231/packages/generic/graphviz-releases/12.2.1/graphviz-12.2.1.tar.gz
  tar -xvf graphviz-12.2.1.tar.gz
  cd graphviz-12.2.1 && ./configure --prefix={{LOCAL_DIR}} --enable-static && make && make install

[group('app')]
install-pynvim:
  uv venv "$HOME/.local/share/nvim/venv"
  uv pip install pynvim -p "$HOME/.local/share/nvim/venv"

[group('app')]
install-neovim:
  git clone https://github.com/neovim/neovim.git
  cd neovim && git checkout v0.11.1
  cd neovim && make CMAKE_BUILD_TYPE=Release
  cd neovim && make CMAKE_INSTALL_PREFIX=$HOME/.local/nvim install
  
[group('app')]
install-texlive:
  # see https://www.tug.org/texlive/quickinstall.html
  curl -fsSLk -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  zcat < install-tl-unx.tar.gz | tar xf -
  cd install-tl-2* && perl ./install-tl

[group('app')]
install-pandoc:
  cabal install pandoc-cli
  curl -fsSLO --output-dir "$HOME/.local/share/man/man1" https://raw.githubusercontent.com/jgm/pandoc/refs/heads/main/pandoc-cli/man/pandoc.1
  curl -fsSLO --output-dir "$HOME/.local/share/man/man1" https://raw.githubusercontent.com/jgm/pandoc/refs/heads/main/pandoc-cli/man/pandoc-lua.1
  curl -fsSLO --output-dir "$HOME/.local/share/man/man1" https://raw.githubusercontent.com/jgm/pandoc/refs/heads/main/pandoc-cli/man/pandoc-server.1

[unix]
[group('app')]
install-hunspell:
  #!/usr/bin/env bash
  git clone https://github.com/hunspell/hunspell.git
  cd hunspell
  autoreconf -vfi
  ./configure --prefix=$HOME/.local
  make
  make install
  sudo ldconfig
  curl -O https://hunspell.memoq.com/de.zip
  unzip -j "de.zip" "de/de_DE.*" -d "$HOME/.local/share/hunspell/"
  curl -O https://hunspell.memoq.com/fr_FR.zip
  unzip -j "fr_FR.zip" "fr_FR/fr.*" -d "$HOME/.local/share/hunspell/"
  curl -O https://hunspell.memoq.com/it_IT.zip
  unzip -j "it_IT.zip" "it_IT/it_IT.*" -d "$HOME/.local/share/hunspell/"
  curl -O https://hunspell.memoq.com/pt_BR.zip
  unzip -j "pt_BR.zip" "pt_BR/pt_BR.*" -d "$HOME/.local/share/hunspell/"
  curl -O https://hunspell.memoq.com/es.zip
  unzip -j "es.zip" "es/es_ES.*" -d "$HOME/.local/share/hunspell/"
  curl -O https://hunspell.memoq.com/en.zip
  unzip -j "en.zip" "en/en_US.*" -d "$HOME/.local/share/hunspell/"

[unix]
[group('app')]
install-imagemagick:
  git clone --depth 1 --branch 7.1.1-47 https://github.com/ImageMagick/ImageMagick.git
  cd ImageMagick && ./configure --prefix={{LOCAL_DIR}} --enable-hdri --enable-64bit-channel-masks --with-modules
  cd ImageMagick && make && make install
  sudo ldconfig "$HOME/.local/lib"

[unix]
[group('app')]
install-emacs:
  # git clone -b emacs-30 git://git.sv.gnu.org/emacs.git
  # cd emacs && ./autogen.sh
  # cd emacs && ./configure --prefix={{LOCAL_DIR}} --with-mailutils --with-tree-sitter --without-xaw3d --with-pgtk --with-native-compilation=aot
  sudo pacman -S emacs-wayland

[unix]
[group('app')]
install-lazyvim:
  # required
  mv ~/.config/nvim{,.bak}

  # optional but recommended
  mv ~/.local/share/nvim{,.bak}
  mv ~/.local/state/nvim{,.bak}
  mv ~/.cache/nvim{,.bak}

  git clone https://github.com/LazyVim/starter ~/.config/nvim
  rm -rf ~/.config/nvim/.git

[unix]
[group('app')]
install-doom:
  git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/doomemacs
  ~/.config/emacs/bin/doom install

[group('lsp')]
install-lsps:
  # see https://langserver.org/
  # see https://microsoft.github.io/language-server-protocol/implementors/servers/

[group('lsp')]
install-tidy:
  git clone https://github.com/htacg/tidy-html5.git
  cd tidy-html5/build/cmake \
    && cmake ../.. -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX={{LOCAL_DIR}} -DBUILD_SHARED_LIB:BOOL=OFF -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    && make \
    && make install

[group('lsp')]
install-typescript-lsp:
  npm install -g typescript-language-server typescript

[group('lsp')]
install-json-lsp:
  npm install -g vscode-json-languageserver

[group('lsp')]
install-kotlin-lsp:
  #!/usr/bin/env bash
  git clone https://github.com/fwcd/kotlin-language-server.git
  cd kotlin-language-server
  . "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java 11.0.27-tem
  ./gradlew :server:installDist
  sdk uninstall java 11.0.27-tem
  cp server/build/install/server/bin/kotlin-language-server "$HOME/.local/bin/"

[group('lsp')]
install-tex-lsp:
  cargo install --git https://github.com/latex-lsp/texlab --locked --tag v5.22.1

[group('lsp')]
install-lua-lsp:
  git clone https://github.com/LuaLS/lua-language-server
  cd lua-language-server && ./make.sh
  mv lua-language-server/bin/lua-language-server "$HOME/.local/bin/"

[group('lsp')]
install-bash-lsp:
  cabal update
  cabal install ShellCheck
  go install mvdan.cc/sh/v3/cmd/shfmt@latest
  npm i -g bash-language-server
  # see also https://github.com/idank/explainshell

[group('lsp')]
install-perl-lsp:
  cpanm --local-lib="$HOME/perl5" Perl::LanguageServer

[group('lsp')]
install-bibtex-lsp:
  uv tool install citation-langserver

[group('lsp')]
install-clangd:
  curl -fsSLO https://github.com/clangd/clangd/releases/download/19.1.2/clangd-linux-19.1.2.zip
  unzip clangd-linux-19.1.2.zip
  cp -R clangd_19.1.2/{bin,lib} "$HOME/.local/"

[group('lsp')]
install-clojure-lsp:
  curl -fsSLO https://raw.githubusercontent.com/clojure-lsp/clojure-lsp/master/install
  chmod u+x install
  ./install --dir "$HOME/.local/bin"

[group('lsp')]
install-dockerfile-lsp:
  npm install -g dockerfile-language-server-nodejs

[group('lsp')]
install-php-lsp:
  curl -fsSLo phpactor.phar --output-dir "$HOME/.local/bin" https://github.com/phpactor/phpactor/releases/latest/download/phpactor.phar
  chmod u+x "$HOME/.local/bin/phpactor.phar"

[group('lsp')]
instlal-python-lsp:
  uv tool install pyright

[group('lsp')]
install-ruby-lsp:
  gem install ruby-lsp

[group('lsp')]
install-yaml-lsp:
   npm install yaml-language-server

[group('lsp')]
install-zig-lsp:
  curl -fsSLo zls.tar.xz https://builds.zigtools.org/zls-linux-x86_64-0.14.0.tar.xz
  tar -xvf zls.tar.xz
  mv zls "$HOME/.local/bin/"

[group('lsp')]
install-java-lsp:
  curl -fsSLo jdtls.tar.gz https://download.eclipse.org/jdtls/milestones/1.46.1/jdt-language-server-1.46.1-202504011455.tar.gz
  tar -xvf jdtls.tar.gz -C "$HOME/.local/etc/eclipse.jdt.ls/"

# Instala pacotes gem (o único necessário até agora é o neovim)
[group('packages')]
install-gem-packages:
  #!/usr/bin/env bash
  for pkg in {{RUBY_PACKAGES}}; do
    gem install "$pkg"
  done

# Instala pacotes Perl
[group('packages')]
install-perl-packages:
  #!/usr/bin/env bash
  perl -I ~/perl5/lib/perl5 -Mlocal::lib
  for pkg in {{PERL_PACKAGES}}; do
    "$HOME/perl5/bin/cpanm" --local-lib="$HOME/perl5" "$pkg"
  done

# Instala pacotes Rust
[group('packages')]
install-rust-packages:
  #!/usr/bin/env bash
  set -euxo pipefail
  for pkg in {{RUST_PACKAGES}}; do
    case "$pkg" in 
      *.git) cargo install --git "http://github.com/$pkg"
      ;;
 
      ripgrep) cargo install --features 'pcre2' "$pkg"
      ;;

      nu) cargo install nu --features "default static-link-openssl system-clipboard" --locked
      ;;

      *) cargo install "$pkg"
      ;;
    esac
  done     

# Instala pacotes Go
[group('packages')]
install-go-packages:
  #!/usr/bin/env bash
  set -euxo pipefail
  for pkg in {{GO_PACKAGES}}; do
    $HOME/.local/go/bin/go install "$pkg"
  done

# Instala pacotes npm
[group('packages')]
install-npm-packages:
  set -euxo pipefail; \
  for pkg in {{NPM_PACKAGES}}; do \
    npm install --global "$pkg"; \
  done

# Instala pacotes python
[group('packages')]
install-python-packages:
  #!/usr/bin/env bash
  set -euxo pipefail
  for pkg in {{PYTHON_PACKAGES}}; do
    uv tool install "$pkg"
  done

# Limpa o que tinha sido instalado anteriormente
[group('achtung!')]
[unix]
remove-os-packages:
  @just remove-os-package {{PACKAGES_UNINSTALL}}

[group('aux')]
[unix]
remove-os-package +pkg:
  sudo pacman --noconfirm -R {{pkg}}

# Instala pacotes do SO
[group('base')]
[unix]
install-os-packages:
  @just _check-os-and-install "{{OS_PACKAGES}}"

# Detecta o sistema operacional e chama a task de instalação correta
_check-os-and-install pkgs:
    #!/usr/bin/env bash
    if [ -f /etc/os-release ]; then
      . /etc/os-release
      distro=$ID
    else
      echo "⚠️ Não foi possível detectar a distribuição Linux."
      exit 1
    fi

    case "$distro" in
      arch|manjaro|garuda)
        just _install-if-missing "{{pkgs}}"
        ;;
      *)
        echo "⚠️ Distribuição '$distro' ainda não implementada."
        exit 1
        ;;
    esac

# Instala pacotes ausentes, usando pacman ou AUR
_install-if-missing pkgs:
    #!/usr/bin/env bash
    set -euxo pipefail
    missing=()
    for pkg in {{pkgs}}; do
      if ! pacman -Qi "$pkg" &>/dev/null; then
        missing+=("$pkg")
      fi
    done

    if [ "${#missing[@]}" -eq 0 ]; then
      echo "✅ Todos os pacotes já estão instalados."
      exit 0
    fi

    echo "📦 Instalando pacotes ausentes: ${missing[*]}"
    for pkg in "${missing[@]}"; do
      echo "→ Verificando: $pkg"
      if pacman -Si "$pkg" &>/dev/null; then
        echo "  → Instalando com pacman"
        sudo pacman -S --noconfirm --needed "$pkg"
      elif command -v paru &>/dev/null; then
        echo "  → Instalando com paru (AUR)"
        paru -S --noconfirm --needed "$pkg"
      elif command -v yay &>/dev/null; then
        echo "  → Instalando com yay (AUR)"
        yay -S --noconfirm --needed "$pkg"
      else
        echo "  ✗ Nenhum helper AUR (paru/yay) encontrado para instalar '$pkg'."
        exit 1
      fi
    done
