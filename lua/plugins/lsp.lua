return {
  {

    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = {
        jdtls = {},
        matlab_ls = {
          -- MATLAB Language Server settings
          filetypes = { "matlab" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(".git", "*.m", "*.mlx")(fname) or vim.loop.cwd()
          end,
          settings = {
            matlab = {
              indexWorkspace = false,
              -- Uncomment and set path if needed:
              -- installPath = "/path/to/your/matlab/installation",
              matlabConnectionTiming = "onStart",
            },
          },
        },
      },
      setup = {
        jdtls = function()
          return true -- avoid duplicate servers
        end,
        -- No special setup needed for matlab_ls, LazyVim will handle it
      },
    },
  },
  -- {
  --
  --   "nvimdev/lspsaga.nvim",
  --   event = "LspAttach",
  --   dependencies = {
  --     "nvim-tree/nvim-web-devicons",
  --     "nvim-treesitter/nvim-treesitter",
  --   },
  --   opts = {}, -- passed to require("lspsaga").setup()
  --   keys = {
  --     { "gh", "<cmd>Lspsaga finder<CR>", desc = "LSP Finder" },
  --     { "gp", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
  --     { "K", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Doc" },
  --     { "gr", "<cmd>Lspsaga rename<CR>", desc = "Rename (Saga)" },
  --     { "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Prev Diagnostic" },
  --     { "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Next Diagnostic" },
  --   },
  --   config = function(_, opts)
  --     require("lspsaga").setup(opts)
  --   end,
  -- },
}
