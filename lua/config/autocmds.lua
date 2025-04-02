-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
  pattern = { "html", "css", "js", "ts", "lua", "dart"},
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
  end,
})
function ColorMyPencils(color) 
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

end


local highlight_group = vim.api.nvim_create_augroup("CustomHighlightOverrides", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = highlight_group,
  pattern = "*", -- Apply to any colorscheme set by LazyVim
  desc = "Apply custom highlights after colorscheme loads",
  callback = function()
    -- Apply transparency settings
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

    -- Define your desired visual selection background color
    local visual_bg = "#56526e" -- Example: A medium grey
    -- Or pick a color from the Rosé Pine palette, e.g., highlight_med
    -- local visual_bg = "#56526e" -- Rosé Pine Moon/Main highlight_med

    -- Override the Visual highlight group
    vim.api.nvim_set_hl(0, "Visual", {
      bg = visual_bg,
      -- fg = nil, -- Keep default foreground (usually best)
      -- bold = false, -- Ensure no bold unless desired
      -- italic = false, -- Ensure no italic unless desired
    })

    -- Add any other highlight overrides here in the future
    -- e.g., vim.api.nvim_set_hl(0, "Comment", { fg = "#908caa", italic = true })
  end,
})

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
  pattern = "*.pde",
  command = "set filetype=java"
})
ColorMyPencils()
