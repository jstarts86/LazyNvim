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
            ["ctrl-x"] = { fn = actions.toggle_ignore, reload = true },
            ["ctrl-h"] = { fn = actions.toggle_hidden, reload = true },
            -- ["ctrl-t"] = { fn = actions.file_edit },
            -- ["ctrl-s"] = { fn = actions.file_sel_to_qf, reload = true },
            -- ["ctrl-p"] = { fn = actions.file_switch, reload = true}
            -- ["ctrl-p"] = { fn = actions.toggle_preview_focus },
          },
        },
      }
    end,
    keys = {
      { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
      { "<leader>C", "<cmd>FzfLua commands<cr>", desc = "Commands" },
    },
  },
}
