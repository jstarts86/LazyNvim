-- ~/.config/nvim/lua/plugins/jupyter.lua
return {
  "geg2102/nvim-jupyter-client",
  config = function()
    require("nvim-jupyter-client").setup({
      template = {
        cells = {
          {
            cell_type = "code",
            execution_count = nil,
            metadata = {},
            outputs = {},
            source = { "# Custom template cell\n" },
          },
        },
        metadata = {
          kernelspec = {
            display_name = "Python 3",
            language = "python",
            name = "python3",
          },
        },
        nbformat = 4,
        nbformat_minor = 5,
      },
      cell_highlight_group = "CurSearch", -- whatever you want here
      -- If custom highlight group then set these manually
      highlights = {
        cell_title = {
          fg = "#ffffff",
          bg = "#000000",
        },
      },
    })

    -- Add cells
    vim.keymap.set("n", "<leader>ja", "<cmd>JupyterAddCellBelow<CR>", {
      desc = "Add Jupyter cell below",
    })
    vim.keymap.set("n", "<leader>jA", "<cmd>JupyterAddCellAbove<CR>", {
      desc = "Add Jupyter cell above",
    })

    -- Cell operations
    vim.keymap.set("n", "<leader>jd", "<cmd>JupyterRemoveCell<CR>", {
      desc = "Remove current Jupyter cell",
    })
    vim.keymap.set("n", "<leader>jm", "<cmd>JupyterMergeCellAbove<CR>", {
      desc = "Merge with cell above",
    })
    vim.keymap.set("n", "<leader>jM", "<cmd>JupyterMergeCellBelow<CR>", {
      desc = "Merge with cell below",
    })
    vim.keymap.set("n", "<leader>jt", "<cmd>JupyterConvertCellType<CR>", { desc = "Convert cell type (code/markdown)" })
    vim.keymap.set("v", "<leader>jm", "<cmd>JupyterMergeVisual<CR>", {
      desc = "Merge selected cells",
    })
    vim.keymap.set(
      "n",
      "<leader>jD",
      "<cmd>JupyterDeleteCell<CR>",
      { desc = "Delete cell under cursor and store in register" }
    )
  end,
}
