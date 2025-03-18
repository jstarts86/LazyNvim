return {
  -- Terminal that toggles like vscode
  -- Sessions and workspaces
  {
    "natecraddock/sessions.nvim",
    lazy = false,
    config = function()
      local sessions = require("sessions")

      local dir = vim.fn.stdpath("data") .. "/sessions"
      vim.fn.mkdir(dir, "p")

      sessions.setup({
        session_filepath = dir,
        absolute = true,
        autosave = true, -- Enable autosave during setup instead of calling start_autosave()
      })
    end,
  },
  {
    "natecraddock/workspaces.nvim",
    dependencies = {
      "natecraddock/sessions.nvim",
      "nvim-telescope/telescope.nvim",
    },
    keys = {

    { "<leader>W", group = "Workspaces and sessions" },
    { "<leader>Wa", ":WorkspacesAdd<cr>", desc = "Add Workspace" },
    { "<leader>Wl", ":SessionsLoad<cr>", desc = "Load Session" },
    { "<leader>Ww", ":Telescope workspaces<cr>", desc = "Open Workspaces" },
    },

    build = function()
      local workspaces = require("workspaces")

      local project_directories = (os.getenv("PROJECT_DIRS") or "")
      for dir in string.gmatch(project_directories, "[^:]+") do
        workspaces.add_dir(dir)
      end

    end,

    config = function()
      local workspaces = require("workspaces")
      local sessions = require("sessions")
      workspaces.sync_dirs()

      -- Updated which-key registration in the correct format

      workspaces.setup({
        hooks = {
          open_pre = {
            -- Use vim commands directly instead of SessionsStop
            function() 
              vim.cmd("silent! SessionsStop")
              vim.cmd("silent! %bdelete!")
            end,
          },
          open = function()
            -- Updated to use the session API in a more current way
            if not sessions.load(nil, { silent = true }) then
              -- If no session was loaded, ensure autosave is enabled
              sessions.setup({ autosave = true })
            end
          end,
        },
      })
    end,
  },
}
