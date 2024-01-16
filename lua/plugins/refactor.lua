return {
  {
    "ThePrimeagen/refactoring.nvim",
    module = { "refactoring", "telescope" },
    keys = {
      {
        "<leader>r",
        desc = "refactor",
      },
      {
        "x",
        "<leader>re",
        "<cmd>Refactor extract<CR>",
        desc = "visual extract",
      },
      {
        "x",
        "<leader>rf",
        "<cmd>Refactor extract_to_file<CR>",
        desc = "Visual extract to file",
      },
      {
        "x",
        "<leader>r",
        "<cmd>Refactor extract_var<CR>",
        desc = "visual extract var",
      },
      {
        "x",
        "<leader>ri",
        "<cmd>Refactor inline_var<CR>",
        desc = "refactor inline var",
      },
      {
        "x",
        "<leader>ri",
        "<cmd>Refactor inline_var<CR>",
        desc = "refactor inline var",
      },
      {
        "<leader>ri",
        "<cmd>Refactor inline_func<CR>",
        desc = "refactor inline func",
      },
      {
        "<leader>rb",
        "<cmd>Refactor extract block",
        desc = "extract_block",
      },
      {
        "<leader>rbf",
        "<cmd>Refactor extract_block_to_file",
        desc = "extract block to file",
      },
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
