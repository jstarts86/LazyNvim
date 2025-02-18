return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    opts = function(_, opts)
      local cmp = require("cmp")
      table.insert(opts.sources, { name = "emoji" })
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      opts.window = {
        completion = {
          border = "rounded",
          winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None",
          scrollbar = false,
          winblend = 0,
        },
        documentation = {
          border = "rounded",
          winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None",
          scrollbar = false,
          winblend = 0,
        },
        error,
      }
      mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = LazyVim.cmp.confirm({ select = auto_select }),
        ["<C-y>"] = LazyVim.cmp.confirm({ select = true }),
        ["<S-CR>"] = LazyVim.cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        ["<C-e>"] = function(fallback)
          cmp.abort()
          fallback()
        end,
      })
    end,
  },
}

