-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- options.lua
vim.opt.guicursor = ""

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.g.autoformat = false
-- vim.g.minipairs_disable = true

vim.opt.swapfile = false
vim.opt.backup = false

local undodir = os.getenv("HOME") .. "/.vim/undodir"

vim.opt.undodir = undodir
vim.opt.undofile = true

vim.opt.scrolloff = 9
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
vim.o.cursorlineopt = "number"
-- vim.opt.conceallevel = 2
vim.g.python3_host_prog = vim.fn.exepath("/opt/anaconda3/bin/python")
vim.g.loaded_python3_provider = nil
-- vim.g.lazyvim_python_lsp = "basedpyright"

vim.g.snacks_animate = false

vim.o.showtabline = 0
-- I find auto open annoying, keep in mind setting this option will require setting
-- a keybind for `:noautocmd MoltenEnterOutput` to open the output again
-- vim.g.molten_auto_open_output = false

-- this guide will be using image.nvim
-- Don't forget to setup and install the plugin if you want to view image outputs
-- vim.g.molten_image_provider = "image.nvim"

-- optional, I like wrapping. works for virt text and the output window
-- vim.g.molten_wrap_output = true

-- Output as virtual text. Allows outputs to always be shown, works with images, but can
-- be buggy with longer images
-- vim.g.molten_virt_text_output = true

-- this will make it so the output shows up below the \`\`\` cell delimiter
-- vim.g.molten_virt_lines_off_by_1 = true
-- IsLinux = function()
--   return jit.os == "Linux"
-- end
--
-- MarkdownMode = function()
--   return vim.g.started_by_firenvim or vim.env["MD_MODE"] == "1"
-- end
--
-- vim.cmd('runtime! plugin/rplugin.vim')
