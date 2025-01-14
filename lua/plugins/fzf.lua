return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    opts = function(_, opts)
      local actions = require("fzf-lua.actions")
      return {
        files = {
          cwd_prompt = false,
          actions = {
            ["alt-."] = { actions.toggle_ignore },
            ["alt-;"] = { actions.toggle_hidden },
          },
        },
      }
    end,
    keys = {
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" }
    }
  },
}
