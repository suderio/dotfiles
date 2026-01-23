-- ┌─────────────────────────┐
-- │ Plugins outside of MINI │
-- └─────────────────────────┘
--
-- This file contains installation and configuration of plugins outside of MINI.
-- They significantly improve user experience in a way not yet possible with MINI.
-- These are mostly plugins that provide programming language specific behavior.
--
-- Use this file to install and configure other such plugins.

-- Make concise helpers for installing/adding plugins in two stages
local add, later, now = MiniDeps.add, MiniDeps.later, MiniDeps.now
local now_if_args = _G.Config.now_if_args
local map = vim.keymap.set
-- Tree-sitter ================================================================

-- Tree-sitter is a tool for fast incremental parsing. It converts text into
-- a hierarchical structure (called tree) that can be used to implement advanced
-- and/or more precise actions: syntax highlighting, textobjects, indent, etc.
--
-- Tree-sitter support is built into Neovim (see `:h treesitter`). However, it
-- requires two extra pieces that don't come with Neovim directly:
-- - Language parsers: programs that convert text into trees. Some are built-in
--   (like for Lua), 'nvim-treesitter' provides many others.
--   NOTE: It requires third party software to build and install parsers.
--   See the link for more info in "Requirements" section of the MiniMax README.
-- - Query files: definitions of how to extract information from trees in
--   a useful manner (see `:h treesitter-query`). 'nvim-treesitter' also provides
--   these, while 'nvim-treesitter-textobjects' provides the ones for Neovim
--   textobjects (see `:h text-objects`, `:h MiniAi.gen_spec.treesitter()`).
--
-- Add these plugins now if file (and not 'mini.starter') is shown after startup.
--
-- Troubleshooting:
-- - Run `:checkhealth vim.treesitter nvim-treesitter` to see potential issues.
-- - In case of errors related to queries for Neovim bundled parsers (like `lua`,
--   `vimdoc`, `markdown`, etc.), manually install them via 'nvim-treesitter'
--   with `:TSInstall <language>`. Be sure to have necessary system dependencies
--   (see MiniMax README section for software requirements).
now_if_args(function()
    add({
        source = "nvim-treesitter/nvim-treesitter",
        -- Update tree-sitter parser after plugin is updated
        hooks = {
            post_checkout = function()
                vim.cmd("TSUpdate")
            end,
        },
    })
    add({
        source = "nvim-treesitter/nvim-treesitter-textobjects",
        -- Use `main` branch since `master` branch is frozen, yet still default
        -- It is needed for compatibility with 'nvim-treesitter' `main` branch
        checkout = "main",
    })

    -- Define languages which will have parsers installed and auto enabled
    local languages = {
        -- These are already pre-installed with Neovim. Used as an example.
        "lua",
        "vimdoc",
        "markdown",
        -- Add here more languages with which you want to use tree-sitter
        -- To see available languages:
        -- - Execute `:=require('nvim-treesitter').get_available()`
        -- - Visit 'SUPPORTED_LANGUAGES.md' file at
        --   https://github.com/nvim-treesitter/nvim-treesitter/blob/main
        --

"bashls",
"clangd",
"clojure_lsp",
"fennel_ls",
"gopls",
"jdtls", -- also install nvim-jdtls
"julials",
"kotlin_lsp",
"lua_ls",
"stylua",
"pyright",
"perlls",
"phpactor",
"ruby_lsp",
"rust_analyzer",
"docker_compose_language_service",
"docker_language_server",
"just",
"kcl",
"http",
"ltex_plus",
"nginx_language_server",
"sqls",
"systemd_lsp",
"toml",
"texlab",
"tinymist",
"vacuum", -- openapi
"yamlls",
"zls",
    }
    local isnt_installed = function(lang)
        return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
    end
    local to_install = vim.tbl_filter(isnt_installed, languages)
    if #to_install > 0 then
        require("nvim-treesitter").install(to_install)
    end

    -- Enable tree-sitter after opening a file for a target language
    local filetypes = {}
    for _, lang in ipairs(languages) do
        for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
            table.insert(filetypes, ft)
        end
    end
    local ts_start = function(ev)
        vim.treesitter.start(ev.buf)
    end
    _G.Config.new_autocmd("FileType", filetypes, ts_start, "Start tree-sitter")
end)

-- Language servers ===========================================================

-- Language Server Protocol (LSP) is a set of conventions that power creation of
-- language specific tools. It requires two parts:
-- - Server - program that performs language specific computations.
-- - Client - program that asks server for computations and shows results.
--
-- Here Neovim itself is a client (see `:h vim.lsp`). Language servers need to
-- be installed separately based on your OS, CLI tools, and preferences.
-- See note about 'mason.nvim' at the bottom of the file.
--
-- Neovim's team collects commonly used configurations for most language servers
-- inside 'neovim/nvim-lspconfig' plugin.
--
-- Add it now if file (and not 'mini.starter') is shown after startup.
now_if_args(function()
    add("neovim/nvim-lspconfig")

    -- Use `:h vim.lsp.enable()` to automatically enable language server based on
    -- the rules provided by 'nvim-lspconfig'.
    -- Use `:h vim.lsp.config()` or 'after/lsp/' directory to configure servers.
    -- Uncomment and tweak the following `vim.lsp.enable()` call to enable servers.
    -- vim.lsp.enable({
    --   -- For example, if `lua-language-server` is installed, use `'lua_ls'` entry
    -- })
end)

-- Formatting =================================================================

-- Programs dedicated to text formatting (a.k.a. formatters) are very useful.
-- Neovim has built-in tools for text formatting (see `:h gq` and `:h 'formatprg'`).
-- They can be used to configure external programs, but it might become tedious.
--
-- The 'stevearc/conform.nvim' plugin is a good and maintained solution for easier
-- formatting setup.
later(function()
    add("stevearc/conform.nvim")

    -- See also:
    -- - `:h Conform`
    -- - `:h conform-options`
    -- - `:h conform-formatters`
    require("conform").setup({
        default_format_opts = {
            -- Allow formatting from LSP server if no dedicated formatter is available
            lsp_format = "fallback",
        },
        -- Map of filetype to formatters
        -- Make sure that necessary CLI tool is available
        formatters_by_ft = { lua = { "stylua" } },
    })
end)

-- Snippets ===================================================================

-- Although 'mini.snippets' provides functionality to manage snippet files, it
-- deliberately doesn't come with those.
--
-- The 'rafamadriz/friendly-snippets' is currently the largest collection of
-- snippet files. They are organized in 'snippets/' directory (mostly) per language.
-- 'mini.snippets' is designed to work with it as seamlessly as possible.
-- See `:h MiniSnippets.gen_loader.from_lang()`.
later(function()
    add("rafamadriz/friendly-snippets")
end)

-- Honorable mentions =========================================================

-- 'mason-org/mason.nvim' (a.k.a. "Mason") is a great tool (package manager) for
-- installing external language servers, formatters, and linters. It provides
-- a unified interface for installing, updating, and deleting such programs.
--
-- The caveat is that these programs will be set up to be mostly used inside Neovim.
-- If you need them to work elsewhere, consider using other package managers.
--
-- You can use it like so:
now_if_args(function()
    add("mason-org/mason.nvim")
    add("mason-org/mason-lspconfig.nvim")
    add("WhoIsSethDaniel/mason-tool-installer.nvim")
    add("j-hui/fidget.nvim")
    add("saghen/blink.cmp")
    require("mason").setup()
    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
        bashls = {},
        clangd = {},
        clojure_lsp = {},
        fennel_ls = {},
        gopls = {},
        -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
        --
        -- Some languages (like typescript) have entire language plugins that can be useful:
        --    https://github.com/pmizio/typescript-tools.nvim
        --
        -- But for many setups, the LSP (`ts_ls`) will work just fine
        -- ts_ls = {},
        --
        jdtls = {}, -- also install nvim-jdtls
        julials = {},
        kotlin_lsp = {},
        lua_ls = {
            -- cmd = { ... },
            -- filetypes = { ... },
            -- capabilities = {},
            settings = {
                Lua = {
                    completion = {
                        callSnippet = "Replace",
                    },
                    -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
                    -- diagnostics = { disable = { 'missing-fields' } },
                },
            },
        },
        stylua = {},
        pyright = {},
        perlls = {},
        phpactor = {},
        ruby_lsp = {},
        rust_analyzer = {},
        -- -- --
        docker_compose_language_service = {},
        docker_language_server = {},
        just = {},
        kcl = {},
        kulala_ls = {},
        ltex_plus = {},
        nginx_language_server = {},
        sqls = {},
        systemd_lsp = {},
        taplo = {}, -- toml
        texlab = {},
        tinymist = {},
        vacuum = {}, -- openapi
        yamlls = {},
        zls = {},

    }
    local ensure_installed = vim.tbl_keys(servers or {})
    require("mason-tool-installer").setup({ ensure_installed = ensure_installed })
    require("mason-lspconfig").setup({
        ensure_installed = {}, -- explicitly set to an empty table (Kickstart populates installs via mason-tool-installer)
        automatic_installation = false,
        handlers = {
            function(server_name)
                local server = servers[server_name] or {}
                -- This handles overriding only values explicitly passed
                -- by the server configuration above. Useful when disabling
                -- certain features of an LSP (for example, turning off formatting for ts_ls)
                server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                require("lspconfig")[server_name].setup(server)
            end,
        },
    })
end)

-- Beautiful, usable, well maintained color schemes outside of 'mini.nvim' and
-- have full support of its highlight groups. Use if you don't like 'miniwinter'
-- enabled in 'plugin/30_mini.lua' or other suggested 'mini.hues' based ones.
now(function()
  add('sainnhe/everforest')
  vim.cmd('color everforest')
end)

now(function()
    add("Olical/nfnl")
end)

now(function()
    add("MunifTanjim/nui.nvim")
    -- OPTIONAL: Choose your preferred markdown renderer (or omit for raw markdown)
    -- Clean rendering
    add("MeanderingProgrammer/render-markdown.nvim")
    -- OR: "OXY2DEV/markview.nvim", -- Rich rendering with advanced features
    add("saxon1964/neovim-tips")
    require("neovim_tips").setup({
        -- OPTIONAL: Daily tip mode (default: 1)
        daily_tip = 2, -- 0 = off, 1 = once per day, 2 = every startup
        -- OPTIONAL: Bookmark symbol (default: "🌟 ")
        bookmark_symbol = "🌟 ",
    })
    map("n", "<leader>nto", ":NeovimTips<CR>", { desc = "Neovim tips", silent = true })
    map("n", "<leader>ntb", ":NeovimTipsBookmarks<CR>", { desc = "Bookmarked tips", silent = true })
    map("n", "<leader>nte", ":NeovimTipsEdit<CR>", { desc = "Edit your Neovim tips", silent = true })
    map("n", "<leader>nta", ":NeovimTipsAdd<CR>", { desc = "Add your Neovim tip", silent = true })
    map("n", "<leader>nth", ":help neovim-tips<CR>", { desc = "Neovim tips help", silent = true })
    map("n", "<leader>ntr", ":NeovimTipsRandom<CR>", { desc = "Show random tip", silent = true })
    map("n", "<leader>ntp", ":NeovimTipsPdf<CR>", { desc = "Open Neovim tips PDF", silent = true })
end)

now(function()
    add("suderio/autolang.nvim")
end)

later(function()
    add("mfussenegger/nvim-jdtls")
end)
