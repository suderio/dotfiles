vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

function DisplayGlobalVariables()
  print("DEBUG: Iniciando DisplayGlobalVariables...")

  local ok, err = pcall(function()
    -- ===================================================================
    -- MUDANÇA PRINCIPAL AQUI
    -- Em vez de iterar com pairs, pedimos diretamente ao Neovim pelas chaves.
    -- Este método é muito mais confiável.
    local keys = vim.fn.keys(vim.g)
    -- ===================================================================

    if #keys == 0 then
      -- Esta mensagem agora só apareceria se vim.g fosse genuinamente vazio.
      vim.notify("Nenhuma variável global (vim.g) foi encontrada.", vim.log.levels.WARN)
      return
    end
    table.sort(keys) -- Ordenamos as chaves como antes
    print("DEBUG: " .. #keys .. " chaves globais encontradas e ordenadas.")

    -- O resto da função continua exatamente igual...
    local content = { "--- Variáveis Globais (vim.g) ---", "" }
    for _, key in ipairs(keys) do
      local value = vim.g[key]
      local value_str

      local inspect_ok, result = pcall(vim.inspect, value)
      if inspect_ok then
        value_str = result:gsub("\n", " "):sub(1, 200)
      else
        value_str = "[Erro ao inspecionar valor]"
      end
      table.insert(content, string.format("vim.g.%-40s = %s", key, value_str))
    end

    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(bufnr, "bufhidden", "wipe")
    vim.api.nvim_buf_set_option(bufnr, "filetype", "lua")
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)

    local width = math.floor(vim.o.columns * 0.8)
    local height = math.floor(vim.o.lines * 0.8)
    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor((vim.o.columns - width) / 2)

    local opts = {
      relative = "editor",
      width = width,
      height = height,
      row = row,
      col = col,
      style = "minimal",
      border = "rounded",
    }
    local win_id = vim.api.nvim_open_win(bufnr, true, opts)

    vim.api.nvim_buf_set_keymap(bufnr, "n", "q", "<cmd>close!<cr>", { noremap = true, silent = true })
  end)

  if not ok then
    vim.notify("Ocorreu um erro: " .. err, vim.log.levels.ERROR)
  end
end

-- Lembre-se de ter seu comando ou atalho para chamar a função
vim.api.nvim_create_user_command("InspectGlobals", DisplayGlobalVariables, {})
vim.keymap.set("n", "<leader>gv", DisplayGlobalVariables, { desc = "Inspect Global Variables (vim.g)" })
