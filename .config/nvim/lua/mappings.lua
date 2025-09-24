local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })

-- ## Modo Insert

map("i", "<C-b>", "<ESC>^i", { desc = "move beginning of line" })
map("i", "<C-e>", "<End>", { desc = "move end of line" })
map("i", "<C-h>", "<Left>", { desc = "move left" })
map("i", "<C-l>", "<Right>", { desc = "move right" })
map("i", "<C-j>", "<Down>", { desc = "move down" })
map("i", "<C-k>", "<Up>", { desc = "move up" })
map("i", "jk", "<ESC>")

-- ## Modo Normal (n)

-- Ponto de entrada para "find file", um dos atalhos mais usados no Doom.
map("n", "<leader>.", "<cmd>Telescope find_files<cr>", { desc = "Find File" })

---
-- F: Arquivos (Files)
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format { lsp_fallback = true }
end, { desc = "general format file" })
-- telescope
map("n", "<leader>fw", "<cmd>Telescope live_grep<CR>", { desc = "telescope live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "telescope find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "telescope help page" })
map("n", "<leader>ma", "<cmd>Telescope marks<CR>", { desc = "telescope find marks" })
map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>", { desc = "telescope find oldfiles" })
map("n", "<leader>fz", "<cmd>Telescope current_buffer_fuzzy_find<CR>", { desc = "telescope find in current buffer" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "telescope git commits" })
map("n", "<leader>gt", "<cmd>Telescope git_status<CR>", { desc = "telescope git status" })
map("n", "<leader>pt", "<cmd>Telescope terms<CR>", { desc = "telescope pick hidden term" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "telescope find files" })
map(
  "n",
  "<leader>fa",
  "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
  { desc = "telescope find all files" }
)

map("n", "<C-s>", "<cmd>w<CR>", { desc = "general save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "general copy whole file" })

map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "File: Find File" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "File: Recent Files" })
map("n", "<leader>fs", "<cmd>write<cr>", { desc = "File: Save" })
map("n", "<leader>fS", "<cmd>write !sudo tee % > /dev/null<cr>", { desc = "File: Save as Sudo" })

---
-- P: Projeto (Project)
map("n", "<leader>pf", "<cmd>Telescope find_files<cr>", { desc = "Project: Find File" })
map("n", "<leader>ps", "<cmd>Telescope live_grep<cr>", { desc = "Project: Search Text" })
map("n", "<leader>pp", "<cmd>Telescope projects<cr>", { desc = "Project: Switch Project" }) -- Requer telescope-project.nvim

---
-- S: Busca (Search)
map("n", "<leader>ss", "<cmd>Telescope live_grep<cr>", { desc = "Search: Text in Project" })
map("n", "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Search: in Current Buffer" })
map("n", "<leader>sh", "<cmd>Telescope help_tags<cr>", { desc = "Search: Help" })
map("n", "<leader>sk", "<cmd>Telescope keymaps<cr>", { desc = "Search: Keymaps" })

---
-- G: Git
map("n", "<leader>gg", "<cmd>Neogit<cr>", { desc = "Git: Neogit (Magit Clone)" })
map("n", "<leader>gs", "<cmd>Neogit<cr>", { desc = "Git: Status" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Git: Branches" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Git: Commits" })
map("n", "<leader>gd", "<cmd>Gitsigns diffthis<cr>", { desc = "Git: Diff" })
map("n", "<leader>gj", function() require("gitsigns").next_hunk() end, { desc = "Git: Next Hunk" })
map("n", "<leader>gk", function() require("gitsigns").prev_hunk() end, { desc = "Git: Previous Hunk" })
map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, { desc = "Git: Preview Hunk" })

---
-- B: Buffers
map("n", "<leader>bb", "<cmd>Telescope buffers<cr>", { desc = "Buffer: List" })
map("n", "<leader>bd", "<cmd>Bdelete<cr>", { desc = "Buffer: Delete" })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Buffer: Next" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Buffer: Previous" })

---
-- W: Janelas (Windows)
map("n", "<C-h>", "<C-w>h", { desc = "switch window left" })
map("n", "<C-l>", "<C-w>l", { desc = "switch window right" })
map("n", "<C-j>", "<C-w>j", { desc = "switch window down" })
map("n", "<C-k>", "<C-w>k", { desc = "switch window up" })

map("n", "<leader>wd", "<cmd>close<cr>", { desc = "Window: Delete" })
map("n", "<leader>ws", "<C-w>s", { desc = "Window: Split Horizontal" })
map("n", "<leader>wv", "<C-w>v", { desc = "Window: Split Vertical" })
map("n", "<leader>ww", "<C-w>w", { desc = "Window: Other Window" })
map("n", "<leader>wh", "<C-w>h", { desc = "Window: Move Left" })
map("n", "<leader>wj", "<C-w>j", { desc = "Window: Move Down" })
map("n", "<leader>wk", "<C-w>k", { desc = "Window: Move Up" })
map("n", "<leader>wl", "<C-w>l", { desc = "Window: Move Right" })
map("n", "<leader>w=", "<C-w>=", { desc = "Window: Balance" })

---
-- C: Código (Code) / LSP
map("n", "<leader>ca", function() vim.lsp.buf.code_action() end, { desc = "Code: Action" })
map("n", "<leader>cd", function() vim.lsp.buf.definition() end, { desc = "Code: Go to Definition" })
map("n", "<leader>cD", function() vim.lsp.buf.declaration() end, { desc = "Code: Go to Declaration" })
map("n", "<leader>ci", function() vim.lsp.buf.implementation() end, { desc = "Code: Go to Implementation" })
map("n", "<leader>cr", function() vim.lsp.buf.rename() end, { desc = "Code: Rename Symbol" })
map("n", "<leader>cs", function() vim.lsp.buf.signature_help() end, { desc = "Code: Signature Help" })
map("n", "<leader>cf", function() vim.lsp.buf.format { async = true } end, { desc = "Code: Format" })

---
-- H: Ajuda (Help)
map("n", "<leader>hc", "<cmd>Telescope commands<cr>", { desc = "Help: Commands" })
map("n", "<leader>hk", "<cmd>Telescope keymaps<cr>", { desc = "Help: Keymaps" })
map("n", "<leader>hh", "<cmd>Telescope help_tags<cr>", { desc = "Help: Tags" })
map("n", "<leader>ht", "<cmd>Telescope themes<cr>", { desc = "Help: Themes" })

---
-- T: Toggle
-- terminal
map("t", "<C-x>", "<C-\\><C-N>", { desc = "terminal escape terminal mode" })

-- new terminals
map("n", "<leader>h", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "terminal new horizontal term" })

map("n", "<leader>v", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "terminal new vertical term" })

-- toggleable
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "terminal toggleable vertical term" })

map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "terminal toggleable horizontal term" })

map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "terminal toggle floating term" })

-- Line number
map("n", "<leader>tn", "<cmd>set nu!<CR>", { desc = "toggle line number" })
map("n", "<leader>tr", "<cmd>set rnu!<CR>", { desc = "toggle relative number" })
-- Cheatsheet
map("n", "<leader>tc", "<cmd>NvCheatsheet<CR>", { desc = "toggle nvcheatsheet" })
-- Comment
map("n", "<leader>/", "gcc", { desc = "toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "toggle comment", remap = true })
-- nvimtree
map("n", "<C-n>", "<cmd>NvimTreeToggle<CR>", { desc = "nvimtree toggle window" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "nvimtree focus window" })
-- terminal
map("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Terminal: Toggle" })
map("n", "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", { desc = "Terminal: Float" })
map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Terminal: Horizontal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Terminal: Vertical" })

---
-- Atalhos fora do Leader
map("n", "]d", function() vim.diagnostic.goto_next() end, { desc = "Next Diagnostic" })
map("n", "[d", function() vim.diagnostic.goto_prev() end, { desc = "Previous Diagnostic" })
map("n", "<C-n>", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle File Explorer" })

---
-- ## Modo Visual (v)
map("v", "<leader>cc", "<cmd>lua require('Comment.api').toggle.linewise.current()<CR>", { desc = "Comment Lines" })

---
-- ## Modo Terminal (t)
map("t", "<esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

--- ### Outros

-- whichkey
map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "whichkey all keymaps" })

map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "whichkey query lookup" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "general clear highlights" })

-- global lsp mappings
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

-- tabufline
if require("nvconfig").ui.tabufline.enabled then
  map("n", "<leader>b", "<cmd>enew<CR>", { desc = "buffer new" })

  map("n", "<tab>", function()
    require("nvchad.tabufline").next()
  end, { desc = "buffer goto next" })

  map("n", "<S-tab>", function()
    require("nvchad.tabufline").prev()
  end, { desc = "buffer goto prev" })

  map("n", "<leader>x", function()
    require("nvchad.tabufline").close_buffer()
  end, { desc = "buffer close" })
end

map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "telescope nvchad themes" })

