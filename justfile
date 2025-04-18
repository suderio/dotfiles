#!/usr/bin/env just --justfile

set working-directory := 'tmp'

# Lista de linguagens/pacotes desejados
OS_PACKAGES := "cmake mpv sxiv jq zip unzip git less curl wget shellcheck file gnupg openssh base-devel xdg-user-dirs xdg-utils php bash-completion"
RUST_PACKAGES := "bat eza ripgrep git-delta bvaisvil/zenith.git du-dust tree-sitter-cli viu fd-find procs ast-grep starship zellij nu"
PYTHON_PACKAGES := "isort pipenv nose nose2 pytest pylatexenc "
RUBY_PACKAGES := "neovim"
RUBY_PACKAGES_NOT_USED := "chef-utils concurrent kramdown kramdown-parser-gfm mixlib-cli mixlib-config mixlib-shellout rexml ruby-tomlrb"
GO_PACKAGES := "github.com/jesseduffield/lazygit@latest github.com/fatih/gomodifytags@latest github.com/cweill/gotests/gotests@latest github.com/x-motemen/gore/cmd/gore@latest golang.org/x/tools/gopls@latest"
NPM_PACKAGES := "prettier bash-language-server node-gyp semver stylelint neovim @mermaid-js/mermaid-cli js-beautify markdownlint"
PERL_PACKAGES := "Neovim::Ext"
MAKE_PACKAGES := "fzf neovim go lua luarocks texlive pandoc pynvim"
FONTS := "FiraCode DejaVuSansMono JetBrainsMono SourceCodePro Hack NerdFontsSymbolsOnly"
OTHER_PACKAGES := "setuptools lynis clamav emacs-wayland github-cli zathura zathura-djvu zathura-ps zathura-cb xdotool lua51 kitty ghostty imagemagick sbcl"
DUNO := "xclip aria2 aspell biber direnv git-lfs gnuplot pass sshfs chafa ueberzugpp zig zshdb shfmt tidy zls bashdb"
PACKAGES_UNINSTALL := "python-pynvim texlive pandoc markdownlint ruby-mixlib-shellout ruby-chef-utils ruby-concurrent ruby-kramdown-parser-gfm ruby-kramdown ruby-mixlib-cli ruby-mixlib-config ruby-rexml ruby-tomlrb lazygit npm bash-language-server node-gyp nodejs-nopt prettier semver stylelint nodejs bat eza ripgrep git-delta zenith dust tree-sitter-cli viu fd procs rustup ruby composer jdk-openjdk kotlin ktlint cpanminus julia gopls python-pipx python-isort python-nose python-nose2 python-pipenv python-pylatexenc python-pytest"

NERD_FONTS_URL := "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/"
NVM_INSTALL_URL := "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.2/install.sh"
KTLINT_INSTALL_URL := "https://github.com/pinterest/ktlint/releases/download/1.5.0/ktlint"
NEOVIM_INSTALL_URL := "https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz"
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
alias t := test
alias c := clean
alias h := hardening

# Task principal - instala todos os pacotes
[linux]
[group('main')]
install:
  echo {{ cache_directory() }}
  echo {{ config_directory() }}
  echo {{ config_local_directory() }}
  echo {{ data_directory() }}
  echo {{ data_local_directory() }}
  echo {{ executable_directory() }}
  echo {{ home_directory() }}
  @just irust
  @just ifonts
  @just install-go
  @just igo
  @just install-python
  @just ipython
  @just install-nvm
  @just inpm # TODO ver como fazer para rodar depois da instalação do nvm (reload .profile)
  @just install-rbenv # TODO recuperar última versão do ruby
  @just igem # TODO recarregar o environment 
  @just install-composer # TODO confirmar se rodou
  @just install-sdkman
  @just install-julia
  @just install-cpan # TODO recarregar o environment
  @just iperl
  @just install-lua
  @just install-fzf
  @just install-pynvim
  @just install-neovim
  @just install-texlive
  @just install-pandoc

[linux]
i2:
  @just install-hunspell # TODO


[linux]
[group('main')]
clean:
  ls {{ join(home_dir(), 'tmp') }}

[linux]
[group('main')]
test:
  #!/usr/bin/env bash
  for pkg in {{OS_PACKAGES}} {{RUST_PACKAGES}} {{PYTHON_PACKAGES}} {{NPM_PACKAGES}}; do
    case "$pkg" in
      pylatexenc) command -v latex2text
      ;;
      *mermaid-cli) command -v mmdc
      ;;
      markdownlint) true
      ;;
      neovim) command -v neovim-node-host; command -v nvim
      ;;
      *) command -v "$pkg"
      ;;
    esac
  done

# Hardening usando lynis
[linux]
[group('main')]
hardening:
  #!/usr/bin/env bash
  # Understand and configure core dumps on Linux - https://linux-audit.com/software/understand-and-configure-core-dumps-work-on-linux/#disable-core-dumps
  echo 'ulimit -c 0' | sudo tee /etc/profile.d/disable-coredumps.sh >/dev/null
  sudo chown root:root /etc/profile.d/disable-coredumps.sh
  sudo chmod 0644 /etc/profile.d/disable-coredumps.sh
  # Linux password security hashing rounds - https://linux-audit.com/authentication/configure-the-minimum-password-length-on-linux-systems/
  sudo pacman --noconfirm -S libpwquality
  # Set default file permissions on Linux with umask - https://linux-audit.com/filesystems/file-permissions/set-default-file-permissions-with-umask/
  echo 'session optional pam_umask.so umask=027' | sudo tee /etc/pam.d/common-session >/dev/null
  sudo chown root:root /etc/pam.d/common-session
  sudo chmod 0644 /etc/pam.d/common-session

# Instala algumas Nerd Fonts
[linux]
[group('base')]
install-fonts:
  for font in {{FONTS}}; do \
    just install-font $font; \
  done
  fc-cache -v

[linux]
[group('aux')]
install-font font:
    mkdir -p "$XDG_DATA_HOME/fonts/{{font}}"
    curl -sL "{{NERD_FONTS_URL}}{{font}}.tar.xz" | unxz | tar -xvf - -C "$XDG_DATA_HOME/fonts/{{font}}"
    chmod -R "u=rwx,g=r,o=r" "$XDG_DATA_HOME/fonts/{{font}}"

[linux]
[group('base')]
install-nvm:
  mkdir -p "$NVM_DIR"
  [ -s "$NVM_DIR/nvm.sh" ] || bash -c 'curl -o- {{NVM_INSTALL_URL}} | bash'
  source "$NVM_DIR/nvm.sh" && nvm install node

[linux]
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
  "$HOME/.rbenv/bin/rbenv" install 3.4.3
  "$HOME/.rbenv/bin/rbenv" global 3.4.3

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
  curl -L -R -O https://www.lua.org/ftp/lua-5.4.7.tar.gz
  tar zxf lua-5.4.7.tar.gz
  cd lua-5.4.7 && make all test
  cd lua-5.4.7 && make install INSTALL_TOP="$HOME/.local"
  curl -L -R -O https://luarocks.github.io/luarocks/releases/luarocks-3.11.1.tar.gz
  tar zxf luarocks-3.11.1.tar.gz
  cd luarocks-3.11.1 && ./configure --prefix="$HOME/.local" --with-lua="$HOME/.local"
  cd luarocks-3.11.1 && make
  cd luarocks-3.11.1 && make install

[group('base')]
install-go:
  rm -rf "$HOME/.local/go"
  curl -LRO https://go.dev/dl/go1.24.2.linux-amd64.tar.gz
  tar -xvf go1.24.2.linux-amd64.tar.gz
  mv go "$HOME/.local/"

[group('base')]
install-fzf:
  git clone https://github.com/junegunn/fzf.git
  cd fzf && ./install --bin

[group('app')]
install-pynvim:
  uv venv "$HOME/.local/share/nvim/venv"
  uv pip install pynvim -p "$HOME/.local/share/nvim/venv"

[group('app')]
install-neovim:
  curl -RL -o nvim.tar.gz https://github.com/neovim/neovim/releases/download/v0.11.0/nvim-linux-x86_64.tar.gz
  tar zxf nvim.tar.gz
  cp -R nvim-linux-x86_64/* "$HOME/.local/"

[group('app')]
install-texlive:
  # see https://www.tug.org/texlive/quickinstall.html
  curl -L -o install-tl-unx.tar.gz https://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz
  zcat < install-tl-unx.tar.gz | tar xf -
  cd install-tl-2* && perl ./install-tl

[group('app')]
install-pandoc:
  curl -RL -o pandoc.tar.gz https://github.com/jgm/pandoc/releases/download/3.6.4/pandoc-3.6.4-linux-amd64.tar.gz
  tar zxf pandoc.tar.gz
  cp -R pandoc-*/* "$HOME/.local/"

[linux]
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
  # TODO baixar esses dicionários e colocar em $HOME/.local/share/hunspell
  # https://hunspell.memoq.com/de.zip
  # https://hunspell.memoq.com/en.zip
  # https://hunspell.memoq.com/es.zip
  # https://hunspell.memoq.com/fr_FR.zip
  # https://hunspell.memoq.com/it_IT.zip
  # https://hunspell.memoq.com/pt_BR.zip
  # unzip -p myarchive.zip path/to/zipped/file.txt >file.txt
  # ou
  # unzip -j "myarchive.zip" "in/archive/file.txt" -d "/path/to/unzip/to"
  
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
    "$HOME/perl5/bin/cpanm" "$pkg"
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
[linux]
remove-os-packages:
  @just remove-os-package {{PACKAGES_UNINSTALL}}

[group('aux')]
[linux]
remove-os-package +pkg:
  sudo pacman --noconfirm -R {{pkg}}

# Instala pacotes do SO
[group('base')]
[linux]
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
