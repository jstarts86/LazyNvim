return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
      "MunifTanjim/nui.nvim",
    },
    keys = {
      {
        "<leader>e",
        function()
          require("neo-tree.command").execute({
            toggle = true,
            source = "filesystem",
            position = "right",
          })
        end,
        desc = "Filesystem right (root dir)",
      },
    },
    opts = {
      window = {
        position = "right"
      },
    },
  },
}
