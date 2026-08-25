# Improvement Plan

## Neovim Configuration Plan

### Current State Analysis
The current Neovim configuration (`.config/nvim`) is built heavily on **LazyVim**, providing an excellent baseline for extensive multi-language development and sysadmin work. The dependencies are properly unified under `mise` using `.config/mise/config.toml` (and environment-specific configurations like `config.apt.toml`), handling language toolchains, basic system requirements (`fd`, `ripgrep`, `lazygit`), and provider bootstrapping (e.g., `mise run neovim`).

### Identified Issues & Areas for Improvement

#### 1. Extraneous Code & Health
- **Problem:** The `lua/plugins/example.lua` file is present in the active configuration directory. Even though it is gated by `if true then return {} end`, its presence can be confusing for a production setup and clutters the plugin structure.
- **Suggestion:** Remove `lua/plugins/example.lua` entirely to maintain code health and avoid accidental inclusion or confusion when extending the configuration.

#### 2. Loading and Performance
- **Problem:** In `.config/nvim/lua/config/lazy.lua`, the property `defaults.lazy` is set to `false`. While this forces custom plugins to load during startup (which might be intentional for stability), it negates some of the performance benefits of LazyVim's lazy-loading strategy.
- **Suggestion:** Evaluate setting `defaults.lazy = true` for faster startup times on new or resource-constrained machines (e.g., WSL2 or older bare metal). Explicitly set `lazy = false` only on plugins that absolutely require it (such as the `dracula` colorscheme).

#### 3. Dependencies Checklist & Clipboard Providers
- **Problem:** While `config.apt.toml` specifies critical packages, seamless cross-platform usage (especially on raw Linux or WSL2) often requires clipboard tools (`xclip`, `wl-clipboard`, `xsel`) which aren't always present out-of-the-box in unprivileged or minimal environments like RHEL.
- **Suggestion:** Explicitly document or manage system clipboard dependencies for different environments within the `mise` tooling (or OS-specific fallback configs) to guarantee immediate out-of-the-box readiness without manual intervention on a fresh install.

#### 4. Mason and Mise Tooling Overlap
- **Problem:** LazyVim uses `mason.nvim` to download LSP servers, linters, and formatters. Concurrently, `mise` installs some identical tools (e.g., `black`, `shellcheck`, `shfmt`) in `config.apt.toml`. This can lead to duplication, mismatched versions, or PATH resolution conflicts.
- **Suggestion:** Align the `mason.nvim` configuration and `mise` manifests explicitly. To adhere to the "Mise-centric Tooling" core principle, either explicitly disable Mason auto-installations in favor of `mise` managing these executables, or explicitly delegate LSP/Linter management exclusively to Mason. Resolving this duality will ensure a deterministic setup process on a new machine.

## Doom Emacs Configuration Plan

### Current State Analysis
The Doom Emacs configuration (`.config/doom`) takes advantage of Doom's *literate programming* module, managing logic through `config.org`. It provides extensive capabilities, heavily utilizing `org-mode` (with journal and roam integrations) and supporting a vast array of languages using `lsp-mode` paired with `emacs-lsp-booster`. However, certain legacy configurations and hardcoded paths require modernization to fully align with community best practices and ensure portability.

### 1. Org Capture Templates Hardcoding
- **Problem:** In `config.org`, the `org-capture-templates` (and some `org-roam` templates) hardcode specific file paths like `"work/2026.org"` and `"inbox.org"`. This is not future-proof and breaks every new year or when migrating to a new organizational structure.
- **Suggestion:** Refactor the capture templates to use dynamic variables or functions to determine the current year (e.g., `(format-time-string "work/%Y.org")`) or use a generalized `work.org` file with datetrees. This aligns with community best practices for maintaining a robust, zero-maintenance capture workflow.

### 2. TRAMP Reliability and Performance
- **Problem:** The TRAMP configuration sets `(setopt tramp-verbose 10)`. While useful for debugging, a verbosity of 10 writes excessively to logs, causing severe slowdowns and I/O bottlenecks when interacting with remote files over SSH. Additionally, hardcoding `tramp-auto-save-directory` to the local temporary file directory can sometimes leak sensitive remote data to the local machine or cause race conditions.
- **Suggestion:** Remove or decrease `tramp-verbose` to standard levels (`3` or nil). Consider using `ControlMaster` and `ControlPersist` in the local `~/.ssh/config` to multiplex SSH connections instead of relying solely on TRAMP-internal optimizations. Ensure TRAMP auto-save directories are handled securely (e.g., by utilizing remote temp directories where appropriate or ensuring local isolation).

### 3. Legacy and Extraneous Configuration
- **Problem:** Some settings may conflict with Doom Emacs' modern defaults. For instance, `toc-org` is manually configured on `org-mode-hook`, but Doom's `:lang org` module handles `toc-org` out of the box if the `+roam2` or `+pretty` flags are used.
- **Suggestion:** Audit `config.org` against modern Doom Emacs defaults (`~/.config/emacs/docs/`). Remove manual package initializations or `use-package!` blocks for packages that Doom already orchestrates natively via `init.el` (e.g., `org-tempo`, `org-journal` configurations which can be done through Doom's module variables).

### 4. Org Directory Pre-loading
- **Problem:** `config.org` states `Org directories must be set before org loads!` but sets them via `setopt` inside an org block. In Doom, `org-directory` is typically set in `config.el` directly (or outside of an `(after! org ...)` block) to ensure it is defined before Org's myriad dependencies initialize.
- **Suggestion:** Ensure core variables like `org-directory` and `org-roam-directory` are defined eagerly, not lazily, to prevent Emacs from creating default `~/org` folders if the user intended a different path (e.g., in a Dropbox/Sync folder).
