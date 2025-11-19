-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "html", "css", "js", "ts", "lua", "dart", "tsx", "jsx"},
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
  end,
})
-- function ColorMyPencils(color) 
-- 	color = color or "rose-pine"
-- 	vim.cmd.colorscheme(color)
--
-- 	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- 	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
--
-- end


-- local highlight_group = vim.api.nvim_create_augroup("CustomHighlightOverrides", { clear = true })
--
-- local function set_custom_highlights()
--   -- Transparent backgrounds
--   vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
--   vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
--
--   -- Custom visual selection color
--   local visual_bg = "#063970"
--   vim.api.nvim_set_hl(0, "Visual", { bg = visual_bg })
-- end
--
-- -- Apply highlights right after color scheme changes
-- vim.api.nvim_create_autocmd("ColorScheme", {
--   group = highlight_group,
--   callback = set_custom_highlights,
-- })
--
-- -- Ensure highlights are enforced after LazyVim fully starts
-- vim.api.nvim_create_autocmd("User", {
--   group = highlight_group,
--   pattern = "LazyVimStarted",
--   callback = set_custom_highlights,
-- })
