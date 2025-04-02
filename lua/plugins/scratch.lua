return {
  "DestopLine/scratch-runner.nvim",
  dependencies = "folke/snacks.nvim",
  opts = {
    sources = {
      javascript = { "node" },
      python = { "python3" or "python" }, -- "py" or "python" if you are on Windows
      -- java = { "java" }, -- "py" or "python" if you are on Windows
    },
    run_key = "<cr>",
  },
}
