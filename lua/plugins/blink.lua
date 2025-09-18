-- Disable nvim-cmp (we're switching to blink.cmp)
local trigger_text = ";"

return {
  {
    "saghen/blink.cmp",
    version = "*",
    dependencies = {
      "rafamadriz/friendly-snippets",
      "moyiz/blink-emoji.nvim",
      "mikavilpas/blink-ripgrep.nvim",
      "xzbdmw/colorful-menu.nvim",
    },
    event = { "InsertEnter"},

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
            padding = 1,
            treesitter = { "lsp" },
            gap = 2,
            columns = { { "kind_icon" }, { "label", "kind", gap = 2 } },
            components = {
              label = {
                width = { fill = true },
                text = function(ctx)
                  return require("colorful-menu").blink_components_text(ctx)
                end,
                highlight = function(ctx)
                  return require("colorful-menu").blink_components_highlight(ctx)
                end,
              },
              label_description = { width = { fill = true } },
              kind_icon = {
                text = function(ctx)
                  local MiniIcons = require("mini.icons")
                  local source = ctx.item.source_name
                  local label = ctx.item.label
                  local icon = source == "LSP" and MiniIcons.get("lsp", ctx.kind)
                    or source == "copilot" and MiniIcons.get("filetype", source)
                    or source == "Path" and (label:match("%.[^/]+$") and MiniIcons.get("file", label) or MiniIcons.get(
                      "directory",
                      ctx.item.label
                    ))
                    or ctx.kind_icon

                  return icon .. " "
                end,
              },
            },
          },
        },
        documentation = {
          auto_show = true,
          -- auto_show_delay_ms = 200,
          treesitter_highlighting = true,
          window = {},
        },
        ghost_text = {
          enabled = vim.g.ai_cmp,
        },
        -- Mirror: <CR> confirm with select = false (no preselect accept)
        list = {
          selection = {
            preselect = true,
            auto_insert = false,
          },
        },
      },

      -- experimental signature help support
      -- signature = { enabled = true },

      sources = {
        -- enable nvim-cmp sources via blink.compat
        -- compat = { "emoji" },
        default = { "lsp", "snippets", "path", "buffer", "dadbod", "emoji" },
        providers = {
          lsp = {
            name = "lsp",
            enabled = true,
            module = "blink.cmp.sources.lsp",
            score_offset = 90,
            -- When linking markdown notes, I would get snippets and text in the
            -- suggestions, I want those to show only if there are no LSP
            -- suggestions
            -- Disabling fallbacks as my snippets wouldn't show up
            -- Enabled fallbacks as this seems to be working now
            -- fallbacks = { "buffer" },
          },
          snippets = {
            name = "snippets",
            opts = {},
            enabled = true,
            max_items = 8,
            min_keyword_length = 2,
            module = "blink.cmp.sources.snippets",
            score_offset = 75,
          },
          emoji = {
            -- Provided by moyiz/blink-emoji.nvim
            name = "emoji",
            module = "blink-emoji",
            score_offset = 5, -- optional: boosts ranking
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
        enabled = false,
        trigger = {},
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
        ["<C-d>"] = { "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "show", "hide", "fallback" },

        -- Like your Shift+CR confirm replace
        -- ["<S-CR>"] = LazyVim.cmp.map({ "accept_and_replace" }),
        -- ["<C-f>"] = { "scroll_signature_up", "fallback" },
        -- ["<C-b>"] = { "scroll_signature_down", "fallback" },

        ["<C-f>"] = { "scroll_documentation_up", "fallback" },
        ["<C-b>"] = { "scroll_documentation_down", "fallback" },
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

      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

      require("blink.cmp").setup(opts)
    end,
  },
}
