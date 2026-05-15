return {
  {
    "ThePrimeagen/refactoring.nvim",
    config = function(_, opts)
      require("refactoring").setup(opts)
    end,
  },
}
