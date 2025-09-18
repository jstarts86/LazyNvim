-- Disable nvim-cmp (we're switching to blink.cmp)
local trigger_text = ";"

return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      "moyiz/blink-emoji.nvim",
      "mikavilpas/blink-ripgrep.nvim",
    },
    event = { "InsertEnter", "CmdlineEnter" },

    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    ---
    opts = {
      snippets = {
        -- Use LazyVim’s snippet expander (LuaSnip under the hood)
        expand = function(snippet, _)
          return LazyVim.cmp.expand(snippet)
        end,
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },

      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          draw = {
            treesitter = { "lsp" },
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = {
          enabled = vim.g.ai_cmp,
        },
        -- Mirror: <CR> confirm with select = false (no preselect accept)
        list = {
          selection = {
            preselect = false,
          },
        },
      },

      -- experimental signature help support
      -- signature = { enabled = true },

      sources = {
        -- enable nvim-cmp sources via blink.compat
        -- compat = { "emoji" },
        default = { "lsp", "path", "snippets", "buffer", "dadbod", "emoji" },
        providers = {
          emoji = {
            -- Provided by moyiz/blink-emoji.nvim
            name = "emoji",
            module = "blink-emoji",
            score_offset = 15, -- optional: boosts ranking
          },
        },
      },

      cmdline = {
        enabled = true,
        keymap = { preset = "cmdline" },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function(ctx)
              return vim.fn.getcmdtype() == ":"
            end,
          },
          ghost_text = { enabled = true },
        },
      },
      signature = {
        enabled = true,
        window = {
          show_documentation = true,
        },
      },

      keymap = {
        -- "enter" preset = Enter accepts if menu visible; respects preselect=false
        preset = "enter",

        -- Match your nvim-cmp mappings
        ["<C-n>"] = { "select_next" },
        ["<C-p>"] = { "select_prev" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },

        -- Like your Shift+CR confirm replace
        -- ["<S-CR>"] = LazyVim.cmp.map({ "accept_and_replace" }),
        ["<C-f>"] = { "scroll_signature_up", "fallback" },
        ["<C-b>"] = { "scroll_signature_down", "fallback" },

        -- default in all keymap presets
        ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },

        -- Optional: quick accept like <C-y> in your base
        ["<C-y>"] = { "select_and_accept" },
      },
    },

    ---@param opts blink.cmp.Config | { sources: { compat: string[] } }
    config = function(_, opts)
      -- setup compat sources (same as LazyVim’s default)
      local enabled = opts.sources.default
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if type(enabled) == "table" and not vim.tbl_contains(enabled, source) then
          table.insert(enabled, source)
        end
      end

      -- Super-tab behavior + AI accept on <Tab>
      if not opts.keymap["<Tab>"] then
        if opts.keymap.preset == "super-tab" then
          opts.keymap["<Tab>"] = {
            require("blink.cmp.keymap.presets").get("super-tab")["<Tab>"][1],
            LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        else
          opts.keymap["<Tab>"] = {
            LazyVim.cmp.map({ "snippet_forward", "ai_accept" }),
            "fallback",
          }
        end
      end

      -- Add Shift-Tab to jump to previous snippet placeholder (like your LuaSnip mapping)
      if not opts.keymap["<S-Tab>"] then
        opts.keymap["<S-Tab>"] = {
          LazyVim.cmp.map({ "snippet_backward" }),
          "fallback",
        }
      end

      -- Unset custom prop to pass blink.cmp validation
      opts.sources.compat = nil

      -- Preserve LazyVim kind overrides (default behavior)
      for _, provider in pairs(opts.sources.providers or {}) do
        ---@cast provider blink.cmp.SourceProviderConfig|{kind?:string}
        if provider.kind then
          local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
          local kind_idx = #CompletionItemKind + 1

          CompletionItemKind[kind_idx] = provider.kind
          ---@diagnostic disable-next-line: no-unknown
          CompletionItemKind[provider.kind] = kind_idx

          ---@type fun(ctx: blink.cmp.Context, items: blink.cmp.CompletionItem[]): blink.cmp.CompletionItem[]
          local transform_items = provider.transform_items
          ---@param ctx blink.cmp.Context
          ---@param items blink.cmp.CompletionItem[]
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = kind_idx or item.kind
              item.kind_icon = LazyVim.config.icons.kinds[item.kind_name] or item.kind_icon or nil
            end
            return items
          end

          provider.kind = nil
        end
      end

      -- Keep your transparent background preference
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

      require("blink.cmp").setup(opts)
    end,
  },
}
