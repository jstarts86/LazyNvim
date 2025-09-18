return {
  "linux-cultist/venv-selector.nvim",
  dependencies = {
    "neovim/nvim-lspconfig",
    {
      "nvim-telescope/telescope.nvim",
      -- branch = "0.1.x",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },
  ft = "python",
  keys = {
    { "<leader>cV", "<cmd>VenvSelect<cr>" },
  },

  opts = function()
    return {
      search = {
        conda_envs = {
          command = "fd '/bin/python$' /opt/anaconda3/envs --full-path -a -L",
          type = "anaconda",
        },
        conda_base = {
          command = "fd '/python$' /opt/anaconda3/bin --full-path -a -L",
          type = "anaconda",
        },
        local_venv = {
          command = "fd '/bin/python$' .venv --full-path -a -L",
          type = "local",
        },
      },
      options = {
        enable_default_searches = false,
        debug = true,
        enable_cached_venvs = true,              -- ✅ allow caching
        cached_venv_automatic_activation = true, -- ✅ auto-activate last used venv
        require_lsp_activation = true,
        activate_venv_in_terminal = true,
        notify_user_on_venv_activation = true,
      },
    }
  end,

  config = function(_, opts)
    require("venv-selector").setup(opts)

    -- Hook venv activation into LSP refresh
    vim.api.nvim_create_autocmd("User", {
      pattern = "VenvActivated",
      callback = function(event)
        local python_path = event.data.path
        vim.notify("Activated venv: " .. python_path, vim.log.levels.INFO)

        local lspconfig = require("lspconfig")
        for _, client in ipairs(vim.lsp.get_active_clients()) do
          if client.name == "basedpyright" or client.name == "pyright" then
            client.config.settings = client.config.settings or {}
            client.config.settings.python = client.config.settings.python or {}
            client.config.settings.python.pythonPath = python_path
            client.stop(true)
            vim.defer_fn(function()
              lspconfig[client.name].manager.try_add()
            end, 100)
          end
          if client.name == "ruff" then
            client.config.settings = client.config.settings or {}
            client.config.settings.python = client.config.settings.python or {}
            client.config.settings.python.pythonPath = python_path
            client.stop(true)
            vim.defer_fn(function()
              lspconfig.ruff.manager.try_add()
            end, 100)
          end
        end
      end,
    })
  end,
}
