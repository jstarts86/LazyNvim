return {
  {
    "ThePrimeagen/refactoring.nvim",
    module = { "refactoring", "telescope" },
    keys = {
      {
        "<leader>r",
        desc = "refactor",
      }
    },
    wants = { "telescope.nvim" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("config.refactoring").setup()
    end,
  },
}
