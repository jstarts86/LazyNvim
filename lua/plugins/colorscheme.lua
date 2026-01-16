return {
  -- THEMES
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    priority = 1000,
    config = function()
      require("rose-pine").setup({
        dark_variant = "moon",
        variant = "auto",
        dim_inactive_windows = false,
        extend_background_behind_borders = true,
        enable = { terminal = true },
        styles = {
          bold = true,
          italic = true,
          transparency = true,
        },
        highlight_groups = {
          CursorLine = { bg = "surface", inherit = false },
          Visual = { bg = "muted", fg = "gold", inherit = false },
        },
      })
      vim.cmd("colorscheme rose-pine")
    end,
  },
  {
    "vague-theme/vague.nvim",
    lazy = true, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    config = function()
      -- NOTE: you do not need to call setup if you don't want to.
      require("vague").setup({
        transparent= true,
        -- optional configuration here
      })
      vim.cmd("colorscheme vague")
    end
  },

  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      dim_inactive = false, -- dims inactive windows
      style = "dark",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        -- Classic Solarized dark background
        hl.Normal = { bg = "#002b36" }
        hl.NormalNC = { bg = "#002b36" }
        hl.CursorLine = { bg = "#001a21" }
        -- hl.LineNr = { bg = "#001a21" }
        -- hl.SignColumn = { bg = "#001a21" }

        hl.VisualNOS = { bg = "#b58900", fg = c.bg }
      end,
    },
  },

  {
    "projekt0n/github-nvim-theme",
    lazy = true,
    priority = 1000,
    config = function()
      require("github-theme").setup({})
    end,
  },

  -- AUTO DARK MODE SWITCHER
  {
    "f-person/auto-dark-mode.nvim",
    config = function()
      require("auto-dark-mode").setup({
        update_interval = 1000, -- ms
        set_dark_mode = function()
          vim.o.background = "dark"
          vim.cmd("colorscheme solarized-osaka")
        end,
        set_light_mode = function()
          vim.o.background = "light"
          vim.cmd("colorscheme modus_operandi")
        end,
      })
      require("auto-dark-mode").init()
    end,
  },
  {
    "miikanissi/modus-themes.nvim",
    priority = 1000,
    config = function()
      require("modus-themes").setup({
        style = "modus_operandi",
        dim_inactive = false,
        transparent = true,
      })
      vim.cmd("colorscheme modus_operandi")
    end,
  },
}
