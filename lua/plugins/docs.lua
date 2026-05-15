return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      -- Allow rendering in nofile buffers (Noice hover windows use buftype=nofile)
      buftypes = {},
      file_types = { "markdown" },
      code = {
        sign = false,
        -- Block-width code cells so Java signatures don't wrap awkwardly
        width = "block",
        right_pad = 1,
      },
      heading = {
        sign = false,
      },
    },
  },

  -- {
  --   "jstarts86/java-docs.nvim",
  --   config = function()
  --     require("java-docs").setup({})
  --   end,
  -- },
}
