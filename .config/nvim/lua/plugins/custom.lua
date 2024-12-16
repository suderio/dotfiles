return {
  {
    "snacks.nvim",
    opts = {
      dashboard = {
        preset = {
          header = [[
          
 _   _                 _           
| \ | |               (_)          
|  \| | ___  _____   ___ _ __ ___  
| . ` |/ _ \/ _ \ \ / / | '_ ` _ \ 
| |\  |  __/ (_) \ V /| | | | | | |
\_| \_/\___|\___/ \_/ |_|_| |_| |_|
                                   
                                   

 ]],
        },
      },
    },
  },
  -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
  -- would overwrite `ensure_installed` with the new value.
  -- If you'd rather extend the default config, use the code below instead:
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- add tsx and treesitter
      vim.list_extend(opts.ensure_installed, {
        "latex",
      })
    end,
  },

  -- add any tools you want to have installed below
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
      },
    },
  },
  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
