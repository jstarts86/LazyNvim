return {
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
          }
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
}
