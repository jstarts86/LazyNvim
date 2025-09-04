return {
  {
    "L3MON4D3/LuaSnip",
    keys = function()
      return {}
    end,
  },
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-emoji",
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0
          and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]
              :sub(col, col)
              :match("%s")
            == nil
      end

      local luasnip = require("luasnip")
      local cmp = require("cmp")
      local compare = require("cmp.config.compare")

      -- ADD THIS SECTION FOR SORTING
      -- We are adding the `sorting` table to the `opts` that LazyVim provides.
      opts.sorting = {
        priority_weight = 2,
        comparators = {
          compare.exact, -- Prioritize exact matches
          compare.order, -- Finally, fall back to the original order
        },
      }
      -- END OF ADDED SECTION

      local supertab_mappings = {
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }

      local preset_insert_mappings = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = LazyVim.cmp.confirm({ select = false }),
        ["<S-CR>"] = LazyVim.cmp.confirm({
          behavior = cmp.ConfirmBehavior.Replace,
        }),
        ["<C-e>"] = function(fallback)
          cmp.abort()
          fallback()
        end,
      })

      opts.mapping = vim.tbl_extend(
        "force",
        preset_insert_mappings,
        supertab_mappings
      )

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
      }

      -- You must return the modified opts table
      return opts
    end,
  },
}
