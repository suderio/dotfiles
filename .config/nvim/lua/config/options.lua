-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font Mono,NotoSansM Nerd Font Mono:h10:#e-subpixelantialias:#h-none"
  vim.g.neovide_text_gamma = 0.0
  vim.g.neovide_text_contrast = 0.5
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_bottom = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_opacity = 0.0
  vim.g.neovide_normal_opacity = 0.8
  vim.g.neovide_floating_shadow = true
  vim.g.neovide_floating_z_height = 10
  vim.g.neovide_light_angle_degrees = 45
  vim.g.neovide_light_radius = 5
  vim.g.neovide_floating_corner_radius = 0.0
end
vim.opt.spelllang = { "en", "pt_br" }
