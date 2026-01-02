return {
  "folke/noice.nvim",
  event = "VeryLazy",
  config = function()
    require("noice").setup({
      cmdline = {
        enabled = true,
        view = "cmdline",
      },
      routes = {
        {
          filter = { event = "notify", find = "pyright" },
          opts = { skip = true },
        },
      },
      presets = {
        bottom_search = false,
        command_palette = false,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
      lsp = {
        hover = {
          enabled = true,
          silent = true,
          opts = { border = "rounded" },
        },
        documentation = {
          ---@type NoiceViewOptions
          -- 'view' determines how the doc is displayed.
          -- Options: "hover" (floating), "split" (new pane), "notify" (toast popups), "popup"
          view = "hover",
          opts = {
            -- 'render' defines the parser used for the content.
            -- Options: "markdown", "plain"
            render = "markdown",

            -- 'format' is a list of strings/templates to build the output.
            -- Options: { "{message}" }, { "{title}", "{message}" }, etc.
            format = { "{message}" },

            -- 'win_options' are standard Neovim window local options (:h winbar)
            win_options = {
              conceallevel = 3, -- Hides markdown syntax (like link URLs)
              concealcursor = "n", -- Keeps text concealed in Normal mode
              wrap = true, -- Wraps long lines
            },
          },
          -- 'replace' is a powerful callback to mutate the message before it renders.
          -- We use this to strip JDTLS junk and fix the resulting spacing.

          replace = function(renderable)
            -- 1. Remove JDTLS links with explicit character class
            -- Match [text](jdt://<everything except closing paren>)
            renderable.message = renderable.message:gsub("%[([^%]]+)%]%(jdt://[^%)]+%)", "%1")

            -- 2. Clean up vertical white space
            renderable.message = renderable.message:gsub("\n\n\n+", "\n\n")

            -- 3. Fix horizontal spacing
            renderable.message = renderable.message:gsub("  +", " ")

            -- 4. Fix indentation gaps in bullet points
            renderable.message = renderable.message:gsub("\n%s+[*%-]%s+", "\n * ")

            return renderable
          end,
        },
        -- markdown = {
        --   hover = true,
        --   signature = true,
        -- },
      },
      views = {
        hover = {
          border = { style = "rounded" },
          size = { max_width = 100, max_height = 40 },
          win_options = {
            wrap = false,
            linebreak = false,
            conceallevel = 3,
            winhighlight = "Normal:NoiceDocNormal,FloatBorder:NoiceDocBorder",
          },
        },
        cmdline = {
          position = { row = "100%", col = 2 },
          size = { width = "100%", height = "auto" },
        },
      },
    })
  end,
  dependencies = {
    "MunifTanjim/nui.nvim",
    "rcarriga/nvim-notify",
  },
}
