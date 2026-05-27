return {
  {
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    event = "BufEnter",
    config = true, -- required due to issue #88
    keys = {
      { "gJd", function() require("goto-preview").goto_preview_definition() end, desc = "Goto Preview Definition" },
      { "gJt", function() require("goto-preview").goto_preview_type_definition() end, desc = "Goto Preview Type Definition" },
      { "gJi", function() require("goto-preview").goto_preview_implementation() end, desc = "Goto Preview Implementation" },
      { "gJD", function() require("goto-preview").goto_preview_declaration() end, desc = "Goto Preview Declaration" },
      { "gJc", function() require("goto-preview").close_all_win() end, desc = "Close All Preview Windows" },
      { "gJp", function() require("goto-preview").goto_preview_references() end, desc = "Goto Preview References" },
    },
  },
}
