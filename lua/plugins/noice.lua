return {
  "folke/noice.nvim",
  event = "VeryLazy",
  config = function()
    require("noice").setup({
      routes = {
        {
          filter = {
            event = "notify",
            find = "pyright",
          },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        -- command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
      lsp = {
        hover = {
          enabled = true,
          silent = true,
          opts = {
            border = "rounded",
            size = { max_width = 80, max_height = 20 }, -- limit hover size
          },
        },
        signature = {
          enabled = true,
        },
        markdown = {
          hover = false, -- disable markdown conversion to avoid large empty spaces
          signature = false,
        },
      },
      views = {
        hover = {
          border = { style = "rounded" },
          size = { max_width = 80, max_height = 20 },
          win_options = {
            wrap = true,
            linebreak = true,
            conceallevel = 0, -- prevents blank areas due to conceal
          },
        },
      },
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
