return {
  {
    "rmagatti/goto-preview",
    dependencies = { "rmagatti/logger.nvim" },
    event = "BufEnter",
    config = true, -- required due to issue #88
    keys = {
      { "gGd", function() require("goto-preview").goto_preview_definition() end, desc = "Goto Preview Definition" },
      { "gGt", function() require("goto-preview").goto_preview_type_definition() end, desc = "Goto Preview Type Definition" },
      { "gGi", function() require("goto-preview").goto_preview_implementation() end, desc = "Goto Preview Implementation" },
      { "gGD", function() require("goto-preview").goto_preview_declaration() end, desc = "Goto Preview Declaration" },
      { "gGc", function() require("goto-preview").close_all_win() end, desc = "Close All Preview Windows" },
      { "gGp", function() require("goto-preview").goto_preview_references() end, desc = "Goto Preview References" },
    },
  },
}
