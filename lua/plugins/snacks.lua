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
        }
      },
      indent = {
        enabled = false,
      },
      buffers = {
        enabled = true,
      },
      words = {
        enabled = true,
      }
    },
  },
}
