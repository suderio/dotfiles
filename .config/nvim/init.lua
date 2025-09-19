vim.cmd([[set mouse=]])

vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.opt.winborder = "rounded"
vim.opt.hlsearch = false
vim.opt.tabstop = 2
vim.opt.cursorcolumn = false
vim.opt.ignorecase = true
vim.opt.shiftwidth = 2
vim.opt.smartindent = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.signcolumn = "yes"

local map = vim.keymap.set
map('n', '<leader>o', ':update<CR> :source<CR>')
map('n', '<leader>w', ':write<CR>')
map('n', '<leader>q', ':quit<CR>')
map('n', '<leader>v', ':e $MYVIMRC<CR>')
map('n', '<leader>z', ':e ~/.bashrc<CR>')
map('n', '<leader>s', ':e #<CR>')
map('n', '<leader>S', ':sf #<CR>')
map({ 'n', 'v' }, '<leader>y', '"+y')
map({ 'n', 'v' }, '<leader>d', '"+d')
map({ 'n', 'v' }, '<leader>c', '1z=')

map('n', '<leader>f', ":Pick files<CR>")
map('n', '<leader>h', ":Pick help<CR>")
map('n', '<leader>e', ":Oil<CR>")
map('n', '<leader>lf', vim.lsp.buf.format)

--- Instala e configura um plugin a partir de uma tabela de especificações.
--
-- A função espera uma tabela onde o primeiro elemento (índice 1) é uma string
-- no formato "usuario/repositorio.nvim". As chaves restantes da tabela são
-- consideradas as opções de configuração para o plugin.
--
-- @param plugin_spec A tabela de especificação do plugin.
--
function Setup_plugin(plugin_spec)
  -- 1. Extrair o nome do plugin (ex: "lewis6991/gitsigns.nvim")
  local plugin_path = plugin_spec[1]
  if not plugin_path or type(plugin_path) ~= "string" then
    print("Erro: A especificação do plugin não contém um caminho de repositório válido no primeiro elemento.")
    return
  end

  -- 2. Fazer a chamada para vim.pack.add com a URL completa do GitHub
  -- Assume que a função vim.pack.add existe no ambiente.
  -- Se não existir, esta linha causará um erro.
  local github_url = "https://github.com/" .. plugin_path
  -- O formato { { src = ... } } é para ser compatível com gerenciadores
  -- que esperam uma lista de plugins.
  vim.pack.add({ { src = github_url } })
  print("Tentando instalar: " .. plugin_path)

  -- 3. Extrair o nome do módulo para o require (ex: "gitsigns")
  -- Usamos string.match para capturar o que vem depois da '/' e antes de '.nvim'
--  local module_name = string.match(plugin_path, "/([^/]+)%.nvim$")
  local module_name = string.match(plugin_path, "/([^/]+)%.nvim$") or string.match(plugin_path, "/([^/]+)$")
  if not module_name then
    print("Erro: Não foi possível extrair o nome do módulo de '" .. plugin_path .. "'. Formato esperado: 'usuario/modulo.nvim'.")
    return
  end

  -- 4. Construir a tabela de configuração (opts)
  -- Criamos uma nova tabela contendo tudo da tabela original, exceto o primeiro elemento.
  local config_opts = {}
  for key, value in pairs(plugin_spec) do
    -- Copia apenas as chaves que são strings (como 'opts', 'config', etc.)
    -- ignorando o elemento de índice numérico [1].
    if type(key) == "string" then
      config_opts[key] = value
    end
  end

  -- 5. Fazer a chamada para require("...").setup(...) de forma segura
  -- Usamos pcall para evitar que um erro no setup de um plugin quebre todo o script.
  local ok, plugin_module = pcall(require, module_name)

  if ok then
    -- Verifica se o módulo retornado tem uma função 'setup'
    if plugin_module and plugin_module.setup then
      print("Configurando '" .. module_name .. "'...")
      plugin_module.setup(config_opts)
    else
      print("Aviso: O módulo '" .. module_name .. "' não possui uma função 'setup'.")
    end
  else
    print("Erro ao carregar o módulo '" .. module_name .. "': " .. tostring(plugin_module))
  end
end




vim.pack.add {
	{ src = "https://github.com/Olical/nfnl" },
  { src = 'https://github.com/neovim/nvim-lspconfig' },
	{ src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
	{ src = "https://github.com/chomosuke/typst-preview.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
}

Setup_plugin({"mason-org/mason.nvim" })
Setup_plugin({"mason-org/mason-lspconfig.nvim"})
Setup_plugin({"WhoIsSethDaniel/mason-tool-installer.nvim",
	ensure_installed = {
		"bashls",
        "checkstyle",
		"clangd",
		"cljfmt",
		"clojure_lsp",
		"cueimports",
		"dagger",
		"docker_compose_language_service",
		"docker_language_server",
		"google-java-format",
		"gopls",
		"jdtls",
		"jsonls",
		"julials",
		"just",
		"kcl",
		"kotlin-debug-adapter",
		"kotlin_language_server",
		"lua_ls",
		"markdownlint-cli2",
		"rust_analyzer",
		"shellcheck",
		"shfmt",
		"stylua",
		"yamlls",
		"zls",
	}
})

vim.lsp.config('lua_ls', {
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
			},
			diagnostics = {
				globals = {
					'vim',
					'require'
				},
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
		},
	},
})

-- colors
Setup_plugin({"vague2k/vague.nvim", transparent = true })
vim.cmd("colorscheme vague")
vim.cmd(":hi statusline guibg=NONE")

Setup_plugin({"NvChad/showkeys", position = "top-right" })
Setup_plugin({"echasnovski/mini.pick" })
Setup_plugin({"stevearc/oil.nvim"})

-- require('nvim-treesitter.configs').setup({ highlight = { enable = true, }, })


-- snippets
Setup_plugin({"L3MON4D3/luasnip", enable_autosnippets = true })
require("luasnip.loaders.from_lua").load({ paths = "~/.config/nvim/snippets/" })

local ls = require("luasnip")
map("i", "<C-e>", function() ls.expand_or_jump(1) end, { silent = true })
map({ "i", "s" }, "<C-J>", function() ls.jump(1) end, { silent = true })
map({ "i", "s" }, "<C-K>", function() ls.jump(-1) end, { silent = true })

-- mini.pairs
Setup_plugin({
  "nvim-mini/mini.pairs",
  opts = {
    modes = { insert = true, command = true, terminal = false },
    -- skip autopair when next character is one of these
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    -- skip autopair when the cursor is inside these treesitter nodes
    skip_ts = { "string" },
    -- skip autopair when next character is closing pair
    -- and there are more closing pairs than opening pairs
    skip_unbalanced = true,
    -- better deal with markdown code blocks
    markdown = true,
  },
})

Setup_plugin({"folke/ts-comments.nvim" })
-- lazydev
-- TODO rever paths
-- require "lazydev".setup({
--   "folke/lazydev.nvim",
--   ft = "lua",
--   cmd = "LazyDev",
--   opts = {
--     library = {
--       { path = "${3rd}/luv/library", words = { "vim%.uv" } },
--       { path = "LazyVim", words = { "LazyVim" } },
--       { path = "snacks.nvim", words = { "Snacks" } },
--       { path = "lazy.nvim", words = { "LazyVim" } },
--     },
--   },
-- })

Setup_plugin({
  "MagicDuck/grug-far.nvim",
  opts = { headerMaxWidth = 80 },
  cmd = { "GrugFar", "GrugFarWithin" },
  keys = {
    {
      "<leader>sr",
      function()
        local grug = require("grug-far")
        local ext = vim.bo.buftype == "" and vim.fn.expand("%:e")
        grug.open({
          transient = true,
          prefills = {
            filesFilter = ext and ext ~= "" and "*." .. ext or nil,
          },
        })
      end,
      mode = { "n", "v" },
      desc = "Search and Replace",
    },
  },
})

Setup_plugin({
  "folke/flash.nvim" ,
  event = "VeryLazy",
  vscode = true,
  ---@type Flash.Config
  opts = {},
  -- stylua: ignore
  keys = {
    { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
    { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
    { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    -- Simulate nvim-treesitter incremental selection
    { "<c-space>", mode = { "n", "o", "x" },
      function()
        require("flash").treesitter({
          actions = {
            ["<c-space>"] = "next",
            ["<BS>"] = "prev"
          }
        })
      end, desc = "Treesitter Incremental Selection" },
  },
})

-- TODO configurar which-key
Setup_plugin(  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
        untracked = { text = "▎" },
      },
      signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
        changedelete = { text = "▎" },
      },
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
        end

        -- stylua: ignore start
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
        map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  })

  Setup_plugin(  -- better diagnostics list and others
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      modes = {
        lsp = {
          win = { position = "right" },
        },
      },
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
      { "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
      { "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
      {
        "[q",
        function()
          if require("trouble").is_open() then
            require("trouble").prev({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cprev)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Previous Trouble/Quickfix Item",
      },
      {
        "]q",
        function()
          if require("trouble").is_open() then
            require("trouble").next({ skip_groups = true, jump = true })
          else
            local ok, err = pcall(vim.cmd.cnext)
            if not ok then
              vim.notify(err, vim.log.levels.ERROR)
            end
          end
        end,
        desc = "Next Trouble/Quickfix Item",
      },
    },
  })

  Setup_plugin(  {
    "folke/todo-comments.nvim",
    cmd = { "TodoTrouble", "TodoTelescope" },
    event = "LazyFile",
    opts = {},
    -- stylua: ignore
    keys = {
      { "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
      { "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
      { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
      { "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
      { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
      { "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
    },
  })
