return {
  {
    "nvim-orgmode/orgmode",
    event = "VeryLazy",
    ft = { "org" },
    config = function()
      -- Setup orgmode
      require("orgmode").setup({
        org_agenda_files = "~/Org/**/*",
        org_default_notes_file = "~/Org/refile.org",
      })

      -- NOTE: If you are using nvim-treesitter with ~ensure_installed = "all"~ option
      -- add ~org~ to ignore_install
      -- require('nvim-treesitter.configs').setup({
      --   ensure_installed = 'all',
      --   ignore_install = { 'org' },
      -- })
    end,
  },
  {
    "saghen/blink.cmp",
    opts_extend = { "orgmode" },
    sources = {
      providers = {
        orgmode = {
          name = "Orgmode",
          module = "orgmode.org.autocompletion.blink",
        },
      },
    },
  },
  { "akinsho/org-bullets.nvim" },
  {
    "mrshmllow/orgmode-babel.nvim",
    dependencies = {
      "nvim-orgmode/orgmode",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "OrgExecute", "OrgTangle" },
    opts = {
      -- by default, none are enabled
      langs = { "python", "lua", ... },

      -- paths to emacs packages to additionally load
      load_paths = {},
    },
  },
}
