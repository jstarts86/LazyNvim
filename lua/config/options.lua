-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.opt.guicursor = ""

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.g.autoformat = false
vim.g.minipairs_disable = true

vim.opt.swapfile = false
vim.opt.backup = false


local undodir = os.getenv("HOME") .. "/.vim/undodir"
if not vim.fn.isdirectory(undodir) then
    vim.fn.mkdir(undodir, "p")
end
vim.opt.undodir = undodir
vim.opt.undofile = true

vim.opt.scrolloff = 9
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"
-- vim.opt.conceallevel = 2
vim.g.python3_host_prog = vim.fn.exepath('/opt/anaconda3/bin/python')
vim.g.loaded_python3_provider = nil

vim.cmd('runtime! plugin/rplugin.vim')
