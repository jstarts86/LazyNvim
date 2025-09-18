-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
  pattern = "*",
  command = "checktime",
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "markdown" },
  callback = function()
    vim.wo.conceallevel = 0
  end,
})
vim.api.nvim_create_autocmd({ "FileType" }, {
  pattern = { "html", "css", "js", "ts", "lua", "dart", "tsx", "jsx"},
  callback = function()
    vim.opt.tabstop = 2
    vim.opt.softtabstop = 2
    vim.opt.shiftwidth = 2
  end,
})
function ColorMyPencils(color) 
	color = color or "rose-pine"
	vim.cmd.colorscheme(color)

	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })

end


local highlight_group = vim.api.nvim_create_augroup("CustomHighlightOverrides", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
  group = highlight_group,
  pattern = "*", -- Apply to any colorscheme set by LazyVim
  desc = "Apply custom highlights after colorscheme loads",
  callback = function()
    -- Apply transparency settings
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        vim.api.nvim_set_hl(0, "Normal", { bg = "none" })

    -- Define your desired visual selection background color
    local visual_bg = "#063970" -- Example: A medium grey
    -- local lsp_ref_bg = "#393552"
    -- Or pick a color from the Rosé Pine palette, e.g., highlight_med
    -- local visual_bg = "#56526e" -- Rosé Pine Moon/Main highlight_med

    -- Override the Visual highlight group
    vim.api.nvim_set_hl(0, "Visual", {
      bg = visual_bg,
      -- fg = nil, -- Keep default foreground (usually best)
      -- bold = false, -- Ensure no bold unless desired
      -- italic = false, -- Ensure no italic unless desired
    })
    -- vim.api.nvim_set_hl(0, "LspReferenceText", { bg = lsp_ref_bg })
    -- vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = lsp_ref_bg })
    -- vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = lsp_ref_bg })
    -- -- DocumentHighlight is often linked to the above, but setting it ensures consistency
    -- vim.api.nvim_set_hl(0, "DocumentHighlight", { bg = lsp_ref_bg }

    -- Add any other highlight overrides here in the future
    -- e.g., vim.api.nvim_set_hl(0, "Comment", { fg = "#908caa", italic = true })
  end,
})
-- vim.api.nvim_create_autocmd("LspAttach", {
--   callback = function(event)
--     local client = vim.lsp.get_client_by_id(event.data.client_id)
--     if client and client.name == "jdtls" then
--       client.handlers['language/status'] = function(_, result)
--       end
--       client.handlers['$/progress'] = function(_, result, ctx)
--       end
--     end
--   end,
-- })

-- vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
--   pattern = "*.pde",
--   command = "set filetype=java"
-- })
-- ColorMyPencils()
-- vim.api.nvim_create_autocmd("BufWinEnter", {
--   callback = function(args)
--     local bt = vim.bo[args.buf].buftype
--     if bt == "nofile" and vim.bo[args.buf].filetype == "markdown" then
--       pcall(vim.api.nvim_buf_call, args.buf, function()
--         vim.opt_local.wrap = true
--         vim.opt_local.linebreak = true
--         vim.opt_local.textwidth = 0
--         vim.opt_local.colorcolumn = ""
--       end)
--     end
--   end,
-- })

-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "java",
--   desc = "Setup jdtls",
--   callback = function()
--     require("jdtls").start_or_attach({
--       capabilities = require("blink.cmp").get_lsp_capabilities(),
--       cmd = { "jdtls" },
--       root_dir = vim.fs.dirname(vim.fs.find({ "gradlew", ".git", "mvnw" }, { upward = true })[1]),
--     })
--   end,
-- })
