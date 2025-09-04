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
        -- filter = {
        --   event = "lsp",
        --   kind = "progress",
        --   cond = function(message)
        --     local client = vim.tbl_get(message.opts, "progress", "client")
        --     if client ~= "jdtls" then
        --       return false
        --     end
        --     local content = vim.tbl_get(message.opts, "progress", "message")
        --     if content == nil then
        --       return false
        --     end
        --     return string.find(content, "Validate") or string.find(content, "Publish")
        --   end,
        -- },
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
