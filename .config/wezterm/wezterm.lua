local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Apply Dracula theme
config.color_scheme = 'Dracula'

-- Set font
config.font = wezterm.font 'FiraCode Nerd Font Mono'
config.font_size = 11.0
config.harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' }

-- Define launch menus for Git Bash and WSL
config.launch_menu = {
  {
    label = 'Git Bash',
    args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '--login' },
  },
  {
    label = 'WSL (Default)',
    args = { 'wsl.exe' },
  },
}

-- Keybindings to launch shells quickly
config.keys = {
  -- Press Alt + G to open Git Bash
  {
    key = 'g',
    mods = 'ALT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'C:\\Program Files\\Git\\bin\\bash.exe', '--login' },
    },
  },
  -- Press Alt + W to open WSL
  {
    key = 'w',
    mods = 'ALT',
    action = wezterm.action.SpawnCommandInNewTab {
      args = { 'wsl.exe' },
    },
  },
}

return config
