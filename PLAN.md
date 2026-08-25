# Neovim Configuration Plan

## Current State Analysis
The current Neovim configuration (`.config/nvim`) is built heavily on **LazyVim**, providing an excellent baseline for extensive multi-language development and sysadmin work. The dependencies are properly unified under `mise` using `.config/mise/config.toml` (and environment-specific configurations like `config.apt.toml`), handling language toolchains, basic system requirements (`fd`, `ripgrep`, `lazygit`), and provider bootstrapping (e.g., `mise run neovim`).

## Identified Issues & Areas for Improvement

### 1. Extraneous Code & Health
- **Problem:** The `lua/plugins/example.lua` file is present in the active configuration directory. Even though it is gated by `if true then return {} end`, its presence can be confusing for a production setup and clutters the plugin structure.
- **Suggestion:** Remove `lua/plugins/example.lua` entirely to maintain code health and avoid accidental inclusion or confusion when extending the configuration.

### 2. Loading and Performance
- **Problem:** In `.config/nvim/lua/config/lazy.lua`, the property `defaults.lazy` is set to `false`. While this forces custom plugins to load during startup (which might be intentional for stability), it negates some of the performance benefits of LazyVim's lazy-loading strategy.
- **Suggestion:** Evaluate setting `defaults.lazy = true` for faster startup times on new or resource-constrained machines (e.g., WSL2 or older bare metal). Explicitly set `lazy = false` only on plugins that absolutely require it (such as the `dracula` colorscheme).

### 3. Dependencies Checklist & Clipboard Providers
- **Problem:** While `config.apt.toml` specifies critical packages, seamless cross-platform usage (especially on raw Linux or WSL2) often requires clipboard tools (`xclip`, `wl-clipboard`, `xsel`) which aren't always present out-of-the-box in unprivileged or minimal environments like RHEL.
- **Suggestion:** Explicitly document or manage system clipboard dependencies for different environments within the `mise` tooling (or OS-specific fallback configs) to guarantee immediate out-of-the-box readiness without manual intervention on a fresh install.

### 4. Mason and Mise Tooling Overlap
- **Problem:** LazyVim uses `mason.nvim` to download LSP servers, linters, and formatters. Concurrently, `mise` installs some identical tools (e.g., `black`, `shellcheck`, `shfmt`) in `config.apt.toml`. This can lead to duplication, mismatched versions, or PATH resolution conflicts.
- **Suggestion:** Align the `mason.nvim` configuration and `mise` manifests explicitly. To adhere to the "Mise-centric Tooling" core principle, either explicitly disable Mason auto-installations in favor of `mise` managing these executables, or explicitly delegate LSP/Linter management exclusively to Mason. Resolving this duality will ensure a deterministic setup process on a new machine.
