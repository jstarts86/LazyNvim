return {
  -- Place Aerial on the left
  {
    "stevearc/aerial.nvim",
    opts = {
      layout = {
        default_direction = "left",
        placement = "edge",
      },
    },
  },

  -- Place Outline on the left
  {
    "hedyhli/outline.nvim",
    opts = {
      window = {
        position = "left",
        width = 25,
      },
    },
  },

  -- Place dadbod-ui on the left
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.db_ui_win_position = "left"
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },

  -- Open claudecode in a tmux pane to the right
  {
    "coder/claudecode.nvim",
    opts = {
      terminal = {
        provider = "external",
        provider_opts = {
          external_terminal_cmd = "tmux split-window -h %s",
        },
      },
    },
  },
}
