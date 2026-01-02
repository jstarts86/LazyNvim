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
    vim.wo.conceallevel = 2
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "html", "css", "js", "ts", "lua", "dart", "tsx", "jsx" },
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
  end,
})
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback = function()
    local clients = vim.lsp.get_active_clients()
    for _, client in ipairs(clients) do
      if client.name == "metals" then
        client.stop()
        vim.notify("Stopped Metals for Java file", vim.log.levels.INFO)
      end
    end
  end,
})
-- Fix for JDTLS internal URIs
vim.api.nvim_create_autocmd("BufReadCmd", {
  pattern = "jdt://*",
  callback = function()
    local buffer = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_option(buffer, "buftype", "nofile")
    vim.api.nvim_buf_set_option(buffer, "modifiable", false)
    -- The LSP client usually handles the content population automatically
    -- if nvim-jdtls is configured correctly.
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
