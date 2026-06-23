return {
  {
    "suderio/autolang.nvim", -- Replace with local path or git repo
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      require("autolang").setup({
        limit_languages = { "en", "pt_BR" },
      })
    end,
  },
}
