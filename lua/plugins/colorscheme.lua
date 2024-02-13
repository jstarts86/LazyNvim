return {
  {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
      vim.cmd("colorscheme rose-pine")
      require("rose-pine").setup({
        disable_backround = true,
        styles = {
          transparency = true,
        },
      })
    end,
  },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "rose-pine",
        },
    }
}
