return {
"folke/noice.nvim",
event = "VeryLazy",
config = function()
  require("noice").setup({
    routes = {
      {
        filter = {
          event = "notify",
          -- Add the specific word or pattern you want to filter out
          find = "pyright",
        },
        opts = { skip = true },
      },
      -- Add more filters as needed
      -- {
      --   filter = {
      --     event = "msg_show",
      --     -- Example for filtering another word
      --     find = "another word",
      --   },
      --   opts = { skip = true },
      -- },
      presets = {
        bottom_search = true, -- use a classic bottom cmdline for search
        -- command_palette = true, -- position the cmdline and popupmenu together
        long_message_to_split = true, -- long messages will be sent to a split
        inc_rename = false, -- enables an input dialog for inc-rename.nvim
        lsp_doc_border = true, -- add a border to hover docs and signature help
      },
    },
  })
end,
dependencies = {
  "MunifTanjim/nui.nvim",
  "rcarriga/nvim-notify",
},
}
