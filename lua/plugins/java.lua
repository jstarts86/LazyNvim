-- return {
-- "nvim-java/nvim-java",
-- config = false,
-- dependencies = {
--   {
--     "neovim/nvim-lspconfig",
--     opts = {
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

-- vim.api.nvim_create_autocmd('FileType', {
-- 	pattern = 'java',
-- 	desc = 'Setup jdtls',
-- 	callback = function()
-- 		require('jdtls').start_or_attach({
-- 			capabilities = require('blink.cmp').get_lsp_capabilities(),
-- 			cmd = { 'jdtls' },
-- 			root_dir = vim.fs.dirname(vim.fs.find({ 'gradlew', '.git', 'mvnw' }, { upward = true })[1]),
-- 		})
-- 	end,
-- })

return {
  {
    "mfussenegger/nvim-jdtls",
    ft = { "java" },
    opts = function(_, opts)
      opts.jdtls = opts.jdtls or {}
      opts.jdtls.capabilities = require("blink.cmp").get_lsp_capabilities()
    end,
  },

  -- {
  --   "elmcgill/springboot-nvim",
  --   dependencies = {
  --       "neovim/nvim-lspconfig",
  --       "mfussenegger/nvim-jdtls"
  --   },
  --   config = function()
  --       local springboot_nvim = require("springboot-nvim")
  --       vim.keymap.set('n', '<leader>Br', springboot_nvim.boot_run, {desc = "Spring Boot Run Project"})
  --       vim.keymap.set('n', '<leader>Bc', springboot_nvim.generate_class, {desc = "Java Create Class"})
  --       vim.keymap.set('n', '<leader>Bi', springboot_nvim.generate_interface, {desc = "Java Create Interface"})
  --       vim.keymap.set('n', '<leader>Be', springboot_nvim.generate_enum, {desc = "Java Create Enum"})
  --       springboot_nvim.setup({})
  --   end
  -- }
}

-- return {'nvim-java/nvim-java'}
