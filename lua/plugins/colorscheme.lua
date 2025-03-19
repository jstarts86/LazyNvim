return {
  {
    "rose-pine/neovim",
    name = "rose-pine-main",
    config = function()
      vim.cmd("colorscheme rose-pine")
      require("rose-pine").setup({
        disable_backround = true,
        styles = {
          transparency = true,
        },
        pallete = {
          main = {
            base = '#131313',
            highlight_low = '#131313'
          },

          moon = {
            base = '#131313',
            highlight_low = '#131313',
          },
        },
      })
    end,
  },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "rose-pine-main",
        },
    }
}
