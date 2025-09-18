-- lua/plugins/lsp-blink-caps.lua
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      pcall(function()
        require("lazy").load({ plugins = { "blink.cmp" } })
      end)
      local ok, blink = pcall(require, "blink.cmp")
      if ok then
        opts.capabilities = vim.tbl_deep_extend(
          "force",
          opts.capabilities or {},
          blink.get_lsp_capabilities()
        )
      end
    end,
  },
}
