return {
  {
    "quarto-dev/quarto-nvim",
    lspFeatures = {
      -- NOTE: put whatever languages you want here:
      languages = { "r", "python", "rust" },
      chunks = "all",
      diagnostics = {
        enabled = true,
        triggers = { "BufWritePost" },
      },
      completion = {
        enabled = true,
      },
    },
    keymap = {
      -- NOTE: setup your own keymaps:
      hover = "H",
      definition = "gd",
      rename = "<leader>rn",
      references = "gr",
      format = "<leader>gf",
    },
    codeRunner = {
      enabled = true,
      default_method = "molten",
    },
    dependencies = {
      {
        "jmbuhr/otter.nvim",
        dev = false,
        dependencies = {
          { "neovim/nvim-lspconfig" },
        },
        opts = {
          lsp = {
            hover = {
              border = require("misc.style").border,
            },
          },
          buffers = {
            set_filetype = true,
          },
          handle_leading_whitespace = true,
        },
      },
    },
  },
}
