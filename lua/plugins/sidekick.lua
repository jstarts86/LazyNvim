return {
  {
    "folke/sidekick.nvim",
    opts = {
      nes = {
        enabled = false, -- disable Copilot LSP / Next Edit Suggestions
      },
      copilot = {
        status = {
          level = vim.log.levels.OFF, -- suppress "not signed in" notification
        },
      },
      cli = {
        mux = {
          backend = "tmux",
          enabled = "false",
          create = "split",
          split = {
            vertical = true, -- vertical or horizontal split
            size = 0.5, -- size of the split (0-1 for percentage)
          },
        },
      }, -- test comment
    },
  },
}
