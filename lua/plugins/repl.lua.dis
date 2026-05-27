-- return { "milanglacier/yarepl.nvim", config = true }
return {
  -- "hkupty/iron.nvim",
  -- keys = {
  --   { "<leader>Rs", "<cmd>IronRepl<cr>", desc = "REPL: Start" },
  --   { "<leader>Rr", "<cmd>IronRestart<cr>", desc = "REPL: Restart" },
  -- },
  -- config = function()
  --   local iron = require("iron.core")
  --
  --   iron.setup({
  --     config = {
  --       scratch_repl = true,
  --       repl_definition = {
  --         java = {
  --           command = function()
  --             -- Check if we are in a Maven project
  --             if vim.fn.findfile("pom.xml", ".;") ~= "" then
  --               return { "mvn", "com.github.johnpoth:jshell-maven-plugin:1.3:run" }
  --             end
  --             return { "jshell" }
  --           end,
  --         },
  --       },
  --       repl_open_cmd = require("iron.view").bottom(12),
  --     },
  --     keymaps = {
  --       visual_send = "<leader>Rc",
  --       send_line = "<leader>Rl",
  --     },
  --   })
  -- end,
  "jpalardy/vim-slime",
  -- The 'init' function runs before the plugin loads.
  -- Slime requires global variables (vim.g) to be set early.
  init = function()
    vim.g.slime_target = "neovim"
    vim.g.slime_no_mappings = 1
    vim.g.slime_bracketed_paste = 1
  end,
  -- We define keys here so LazyVim can load the plugin only when needed
  -- and show them in the which-key menu.
  keys = {
    { "<leader>Rs", "<Plug>SlimeParagraphSend", mode = "n", desc = "REPL: Send Paragraph" },
    { "<leader>Rs", "<Plug>SlimeRegionSend", mode = "x", desc = "REPL: Send Selection" },
    { "<leader>Rl", "<Plug>SlimeLineSend", mode = "n", desc = "REPL: Send Line" },
    { "<leader>Rc", "<Plug>SlimeConfig", mode = "n", desc = "REPL: Configure Slime" },
    {
      "<leader>Rt",
      function()
        if vim.g.slime_target == "neovim" then
          vim.g.slime_target = "tmux"
          print("Slime Target: tmux")
        else
          vim.g.slime_target = "neovim"
          print("Slime Target: neovim")
        end
        -- Trigger config to refresh the setup for the new target
        vim.cmd("SlimeConfig")
      end,
      desc = "REPL: Toggle Tmux/Neovim",
    },
  },
}
