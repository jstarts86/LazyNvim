return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = false,
    opts = {
      disable_backround = true,
      background = "light",
      variant = "dawn",
      styles = {
        transparency = true,
      },
      pallete = {
        main = {
          base = "#131313",
          highlight_low = "#1f1f1f",
        },

        moon = {
          base = "#131313",
          highlight_low = "#1f1f1f",
        },
      },
      highlight_groups = {
        Visual = {
          -- Override the Visual selection highlight group
          -- Choose your desired background color
          bg = "#063970", -- Example: Bright 'iris' from Rosé Pine palette
          -- visual_bg = "#063970", -- Example: A medium greyb
          -- Other bright examples:
          -- bg = "#ebbcba", -- 'rose'
          -- bg = "#f6c177", -- 'gold'
          -- bg = "#9ccfd8", -- 'foam'

          -- Optional: Set foreground for better contrast if needed
          fg = "#191724", -- Example: Use the base background for text color
        },

        -- You can add other overrides here too, directly using hex codes
        -- or palette color names (as strings) if preferred.
        -- Example using palette name:
        -- Comment = { fg = "foam", italic = true },
        -- Example using hex code:
        -- Keyword = { fg = "#c4a7e7", bold = true },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "rose-pine-dawn",
    },
  },
}
