return {
  {
    "suderio/autolang.nvim", -- Replace with local path or git repo
    event = { "BufReadPost", "BufWritePost" },
    config = function()
      require("autolang").setup({
        -- Your custom config here (optional)
      })
    end,
  },
}
