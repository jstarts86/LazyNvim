return {
  -- "neovim/nvim-lspconfig",
  -- config = function()
  --   local lspconfig = require("lspconfig")
  --   lspconfig.clangd.setup({
  --     cmd = { "clangd", "--background-index" },
  --     filetypes = { "c", "cpp", "objc", "objcpp" },
  --     root_dir = function() return vim.loop.cwd() end,
  --     single_file_support = true,
  --     flags = {
  --       debounce_text_changes = 150,
  --     },
  --     -- Specify the include path for Gumbo installed via Homebrew
  --     capabilities = vim.lsp.protocol.make_client_capabilities(),
  --     init_options = {
  --       compilationDatabasePath = "build",
  --       includePath = { "/opt/homebrew/include/*" }
  --     },
  --   })
  -- end,
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = function()
  --     vim.schedule(function() vim.cmd("LspStart") end)
  --   end,
  -- },
}
