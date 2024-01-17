-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

local keymap = vim.keymap
local opts = { noremap = true, silent = true }

keymap.set("x", "<leader>re", ":Refactor extract ")
keymap.set("x", "<leader>rf", ":Refactor extract_to_file ")

keymap.set("x", "<leader>rv", ":Refactor extract_var ")

keymap.set({ "n", "x" }, "<leader>ri", ":Refactor inline_var")

keymap.set( "n", "<leader>rI", ":Refactor inline_func")

keymap.set("n", "<leader>rb", ":Refactor extract_block")
keymap.set("n", "<leader>rbf", ":Refactor extract_block_to_file")

