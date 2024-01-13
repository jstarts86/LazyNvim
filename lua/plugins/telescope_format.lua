return {

  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "bottom",
          },
        },
        sorting_strategy = "ascending",
      },
    },
  },
}
