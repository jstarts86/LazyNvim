return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    opts = {
      disable_background = true,
      variant = "moon",
      styles = {
        transparency = true,
      },
      highlight_groups = {
        -- Transparent background
        Normal = { bg = "none" },
        NormalFloat = { bg = "none" },
        -- Lighter visual highlight
        Visual = { bg = "#6fa7e6" },
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
