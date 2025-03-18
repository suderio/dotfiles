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
        org_todo_keywords = { "TODO(t)", "DOING(g)", "WAITING(w)", "|", "DONE(d)" },
        win_split_mode = "float",
        win_border = "rounded",
        org_startup_folded = "content",
        org_todo_keyword_faces = {
          WAITING = ":foreground blue :weight bold",
          DOING = ":background #FFFFFF :slant italic :underline on",
          TODO = ":background #000000 :foreground red",
          DONE = ":background #000000 :foreground white",
        },
        org_archive_location = "%s_archive::",
        org_hide_leading_stars = true,
        calendar_week_start_day = 0,
        org_agenda_span = "day",
        org_agenda_start_on_weekday = false,
        org_capture_templates = {
          J = {
            description = "Journal",
            template = "\n*** %<%Y-%m-%d> %<%A>\n**** %U\n\n%?",
            target = "~/Org/journal/%<%Y-%m>.org",
          },
        },
        org_agenda_skip_scheduled_if_done = true,
        org_agenda_skip_deadline_if_done = true,
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
