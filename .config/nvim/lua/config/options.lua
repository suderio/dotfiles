-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local function setup_clipboard()
  local clipboard_tools = { "xclip", "wl-copy", "xsel", "clip.exe" }
  local has_clipboard = false

  for _, tool in ipairs(clipboard_tools) do
    if vim.fn.executable(tool) == 1 then
      has_clipboard = true
      break
    end
  end

  if has_clipboard then
    vim.opt.clipboard = "unnamedplus"
  else
    vim.schedule(function()
      vim.notify(
        "No supported clipboard tool found (xclip, wl-clipboard, xsel, clip.exe). System clipboard integration is disabled.",
        vim.log.levels.WARN,
        { title = "Clipboard" }
      )
    end)
  end
end

setup_clipboard()
