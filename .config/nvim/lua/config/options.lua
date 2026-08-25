-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.clipboard = "unnamedplus"

local function warn_clipboard()
  local clipboard_tools = { "xclip", "wl-copy", "xsel", "clip.exe" }

  for _, tool in ipairs(clipboard_tools) do
    if vim.fn.executable(tool) == 1 then
      return
    end
  end

  vim.schedule(function()
    vim.notify(
      "No supported clipboard tool found (xclip, wl-clipboard, xsel, clip.exe). System clipboard integration is disabled.",
      vim.log.levels.WARN,
      { title = "Clipboard" }
    )
  end)
end

warn_clipboard()
