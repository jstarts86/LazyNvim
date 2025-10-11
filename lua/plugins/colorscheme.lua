return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    opts = {
      disable_backround = true,
      background = "light",
      variant = "moon",
      styles = {
        transparency = true,
      },
      pallete = {
        main = {
          base = "##0e6bde",
          highlight_low = "#063970",
        },
        moon = {
          base = "##0e6bde",
          highlight_low = "#063970",
        },
      },
      highlight_groups = {
        Visual = {
          -- lighter version of #063970
          bg = "#0e6bde",
          fg = "#191724", -- keep text readable
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-moon",
    },
  },
}
