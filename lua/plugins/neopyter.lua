-- ~/.config/nvim/lua/plugins/neopyter.lua
return {
  "SUSTech-data/neopyter",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "AbaoFromCUG/websocket.nvim",
  },
  opts = {
    mode = "direct",
    remote_address = "127.0.0.1:9001",
    file_pattern = { "*.ju.*", "*.ipynb" },
    log_level = "debug",
  },
  keys = {
    { "<leader>jr", ":Neopyter execute notebook:run-cell<CR>", desc = "Run cell" },
    -- Execution
    { "<leader>ja", ":Neopyter execute notebook:run-all-above<CR>", desc = "Run all above" },
    { "<leader>jn", ":Neopyter execute notebook:run-cell-and-select-next<CR>", desc = "Run and move next" },
    { "<leader>jk", ":Neopyter execute kernelmenu:restart<CR>", desc = "Restart kernel" },

    -- Navigation
    { "<leader>jj", ":Neopyter execute notebook:select-next-cell<CR>", desc = "Next cell" },
    { "<leader>jJ", ":Neopyter execute notebook:select-above-cell<CR>", desc = "Prev cell" },

    -- Structural edits
    { "<leader>jO", ":Neopyter execute notebook:insert-cell-above<CR>", desc = "Insert cell above" },
    { "<leader>jo", ":Neopyter execute notebook:insert-cell-below<CR>", desc = "Insert cell below" },
    { "<leader>jd", ":Neopyter execute notebook:delete-cell<CR>", desc = "Delete cell" },
    { "<leader>jc", ":Neopyter execute notebook:change-cell-to-code<CR>", desc = "Convert to code" },
    { "<leader>jm", ":Neopyter execute notebook:change-cell-to-markdown<CR>", desc = "Convert to markdown" },
  },
  lazy = false
}
