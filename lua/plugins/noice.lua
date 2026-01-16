return {
  "folke/noice.nvim",
  event = "VeryLazy",
  config = function()
    require("noice").setup({
      -- ✅ restore native cmdline (bottom)
      cmdline = {
        enabled = true,
        view = "cmdline",
      },

      routes = {
        {
          filter = { event = "notify", find = "pyright" },
          opts = { skip = true },
        },
      },

      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },

      lsp = {
        hover = {
          enabled = true,
          silent = true,
          opts = {
            border = "rounded",
          },
        },
        documentation = {
          view = "hover",
          opts = {
            render = "plain",
            format = { "{message}" },
            win_options = {
              conceallevel = 3,
              concealcursor = "n",
            },
          },
        },
        markdown = {
          hover = false,
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
            conceallevel = 3,
          },
        },
        cmdline = {
          position = {
            row = "100%",
            col = 2,
          },
          size = {
            width = "100%",
            height = "auto",
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
