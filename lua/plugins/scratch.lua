return {
  "DestopLine/scratch-runner.nvim",
  dependencies = "folke/snacks.nvim",
  opts = {
    sources = {
      javascript = { "node" },
      python = { "python3" or "python" }, -- "py" or "python" if you are on Windows
      java = function(file_path)
        local version = (vim.fn.system("java -version 2>&1") or ""):match('"(%d+)')
        return { "java", "--enable-preview", "--source", version or "21", file_path }
      end,
    },
    run_key = "<cr>",
  },
}
