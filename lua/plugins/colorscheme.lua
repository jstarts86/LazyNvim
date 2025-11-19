return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        dark_variant = "moon",
        variant = "auto",
        dim_inactive_windows = false,
        extend_background_behind_borders = true,
        enable = {
          terminal = true,
        },
        styles = {
          bold = true,
          italic = true,
          transparency = true,
        },
        highlight_groups = {
          -- Comment = { fg = "foam" },
          -- VertSplit = { fg = "muted", bg = "muted" },
          -- StatusLine = { fg = "love", bg = "love", blend = 15 },
          CursorLine = { bg = "surface", inherit = false },
          -- Visual = { fg = "gold", bg = "text", blend = 15 },
          Visual = { bg = "iris", inherit = false },
        },
      })
      vim.cmd("colorscheme rose-pine")
    end,
  },
}
