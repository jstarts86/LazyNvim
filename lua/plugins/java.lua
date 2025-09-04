-- return {
  -- "nvim-java/nvim-java",
  -- config = false,
  -- dependencies = {
  --   {
  --     "neovim/nvim-lspconfig",
  --     opts = {
  --       servers = {
  --         -- Your JDTLS configuration goes here
  --         jdtls = {
  --           settings = {
  --             java = {
  --               configuration = {
  --                 runtimes = {
  --                   -- {
  --                   --   name = "Java21",
  --                   --   path = "/usr/bin/java",
  --                   -- },
  --                 },
  --               },
  --             },
  --           },
  --         },
  --       },
  --       setup = {
  --         jdtls = function()
  --           -- Your nvim-java configuration goes here
  --           require("java").setup({
  --             root_markers = {
  --               "settings.gradle",
  --               "settings.gradle.kts",
  --               "pom.xml",
  --               "build.gradle",
  --               "mvnw",
  --               "gradlew",
  --               "build.gradle",
  --               "build.gradle.kts",
  --             },
  --           })
  --         end,
  --       },
  --     },
  --   },
  -- },
-- }

return {
  "mfussenegger/nvim-jdtls",
  opts = function(_, opts)
    opts.handlers = vim.tbl_extend("force", opts.handlers or {}, {
      ['language/status'] = function(_, result)
        -- Print or whatever.
      end,
      ['$/progress'] = function(_, result, ctx)
        -- disable progress updates.
      end,
    })
    return opts
  end,
}
