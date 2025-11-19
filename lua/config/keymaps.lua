-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- keymaps.lua

local map = vim.keymap.set
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

-- keymap.set('i', '<Esc>', function()
--   vim.lsp.buf.signature_help({ cancel = true })
--   return "<Esc>"
-- end, { expr = true, silent = true })

keymap.set("v", "J", ":m '>+1<CR>gv=gv")
keymap.set("v", "K", ":m '<-2<CR>gv=gv")

keymap.set("i", "<c-y>", "<cmd>call augment#Accept()<cr>")

Snacks.toggle.option("showtabline", {
    off = 0, -- Tabline is off by default
    on = 2,  -- Enable tabline explicitly when toggled
    name = "mine Tabline"
}):map("<leader>uA")

-- Function to toggle the tabline
-- local function toggle_tabline()
--   if vim.o.showtabline == 0 then
--     vim.o.showtabline = 2  -- Always show tabline
--   else
--     vim.o.showtabline = 0  -- Never show tabline
--   end
-- end

-- Map the toggle function to a keybinding (e.g., <leader>bt)
-- map("n", "<leader>uA", toggle_tabline, { desc = "Toggle Tabline" })
-- keymap.set("n", "J", ":m '>+1<CR>gv=gv")
-- keymap.set("n", "K", ":m '<-2<CR>gv=gv")
--
-- Molten
-- keymap.set("n", "<leader>ri", ":MoltenInit<CR>", { silent = true, desc = "Initialize the plugin" })
-- keymap.set("n", "<leader>re", ":MoltenEvaluateOperator<CR>",{ silent = true, desc = "run operator selection" })
-- keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>", { silent = true, desc = "evaluate line" })
-- keymap.set("n", "<leader>rR", ":MoltenReevaluateCell<CR>", { silent = true, desc = "re-evaluate cell" })
-- keymap.set("v", "<leader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", { silent = true, desc = "evaluate visual selection" })
-- keymap.set("n", "<leader>rd", ":MoltenDelete<CR>", { silent = true, desc = "molten delete cell" })
-- keymap.set("n", "<leader>rh", ":MoltenHideOutput<CR>", { silent = true, desc = "hide output" })
-- keymap.set("n", "<leader>ros", ":noautocmd MoltenEnterOutput<CR>", { silent = true, desc = "show/enter output" })
--
--
-- local runner = require("quarto.runner")
-- keymap.set("n", "<localleader>ra", runner.run_above, { desc = "run cell and above", silent = true })
-- keymap.set("n", "<localleader>rA", runner.run_all,   { desc = "run all cells", silent = true })
-- keymap.set("n", "<localleader>rl", runner.run_line,  { desc = "run line", silent = true })
-- keymap.set("n", "<localleader>rc", runner.run_cell,  { desc = "run cell", silent = true })
-- keymap.set("v", "<localleader>r",  runner.run_range, { desc = "run visual range", silent = true })
-- keymap.set("n", "<localleader>RA", function()
--   runner.run_all(true)
-- end, { desc = "run all cells of all languages", silent = true })
-- Toggle between light and dark modes
vim.keymap.set("n", "<leader>tb", function()
  if vim.o.background == "dark" then
    vim.o.background = "light"
  else
    vim.o.background = "dark"
  end
  print("Background set to: " .. vim.o.background)
end, { desc = "Toggle background (light/dark)" })

-- keymap.set("n", "<leader>ip", function()
--   local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
--   if venv ~= nil then
--     venv = string.match(venv, "/.+/(.+)")
--     vim.cmd(("MoltenInit %s"):format(venv))
--   else
--     vim.cmd("MoltenInit python3")
--   end
-- end, { desc = "Initialize Molten for python3", silent = true })
