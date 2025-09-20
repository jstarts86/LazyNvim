return {
  -- lazy.nvim
  {
    "folke/snacks.nvim",
    -- lazy = false,
    opts = {
      picker = {
        sources = {
          explorer = {
            enabled = true,
            layout = {
              preset = "sidebar",
              preview = false,
              layout = {
                position = "right",
              },
            },
            auto_close = true,
          },
        },
        win = {
          input = {
            keys = {
              ["<C-h>"] = { "toggle_hidden", mode = { "i", "n" } },
              ["<C-e>"] = { "toggle_ignored", mode = { "i", "n" } },
              ["<C-l>"] = { "focus_preview", mode = { "i", "n" } },
              ["<C-w>"] = { "cycle_win", mode = { "i", "n" } },
            },
          },
          list = {
            keys = {
              ["<C-h>"] = "toggle_hidden",
              ["<C-e>"] = "toggle_ignored",
              ["<C-l>"] = "focus_preview",
              ["<C-w>"] = "cycle_win",
            },
          },
          preview = {
            keys = {
              ["<C-l>"] = "focus_preview",
              ["<C-w>"] = "cycle_win",
            },
          },
        },
      },

      indent = {
        enabled = false,
      },
      buffers = {
        enabled = true,
      },
      words = {
        enabled = true,
      },
      keys = {
        {
          "<leader>uC",
          function()
            Snacks.picker("colorschemes") -- ✅ call picker by name
          end,
          desc = "Colorschemes",
        },
      },
    },
  },
}
