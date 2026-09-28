return {
  -- LazyVim's luasnip extra only wires the from_vscode loader, so custom Lua
  -- snippets under ~/.config/nvim/luasnippets/ (currently java.lua) never load
  -- without this. Path is explicit rather than relying on a runtimepath scan.
  {
    "L3MON4D3/LuaSnip",
    opts = function()
      require("luasnip.loaders.from_lua").lazy_load({
        paths = { vim.fn.stdpath("config") .. "/luasnippets" },
      })
    end,
  },
}
