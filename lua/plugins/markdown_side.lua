return {
  {
    "blackhat-7/vellum.nvim",
    enabled = true,
    ft = "markdown",
    keys = { { "<leader>mp", "<cmd>Vellum<cr>", desc = "Markdown preview" } },
    config = function(_, opts)
      local vellum = require("vellum")
      vellum.setup(opts)
      local real_open = vellum.open
      vellum.open = function()
        real_open()
        for _, au in ipairs(vim.api.nvim_get_autocmds({ group = "vellum", event = "BufHidden" })) do
          vim.api.nvim_del_autocmd(au.id)
        end
      end
    end,
  },
  -- {
  --   "brianhuster/live-preview.nvim",
  --   dependencies = {
  --     -- You can choose one of the following pickers
  --     "folke/snacks.nvim",
  --   },
  --   ft = "markdown",
  --   keys = { { "<leader>mp", "<cmd>LivePreview start<cr>", desc = "Markdown preview", ft = "markdown" } },
  -- },
}
