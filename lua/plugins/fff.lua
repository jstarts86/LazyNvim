local function root_dir()
  return LazyVim.root({ normalize = true })
end

local function cwd()
  return vim.fs.normalize((vim.uv or vim.loop).cwd() or ".")
end

local function visual_or_cword()
  local mode = vim.fn.mode()
  if mode:find("[vV\22]") then
    local saved = vim.fn.getreg("v")
    vim.cmd([[noautocmd silent normal! "vy]])
    local text = vim.fn.getreg("v")
    vim.fn.setreg("v", saved)
    return text
  end

  return vim.fn.expand("<cword>")
end

local function find_files(dir)
  return function()
    require("fff").find_files({ cwd = dir() })
  end
end

local function live_grep(dir, opts)
  return function()
    require("fff").live_grep(vim.tbl_deep_extend("force", { cwd = dir() }, opts or {}))
  end
end

local function setup_input_focus_keymaps()
  local ui = require("fff.picker_ui")
  local setup_keymaps = ui.setup_keymaps

  ui.setup_keymaps = function(...)
    setup_keymaps(...)

    local state = ui.state
    if not state or not state.input_buf then
      return
    end

    local opts = { buffer = state.input_buf, noremap = true, silent = true }
    vim.keymap.set({ "i", "n" }, "<C-l>", ui.focus_preview_win, opts)
    vim.keymap.set({ "i", "n" }, "<C-w>", ui.focus_list_win, opts)
  end
end

return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false,
    opts = {
      debug = {
        enabled = true,
        show_scores = true,
      },
      layout = {
        preview_position = "right",
      },
      preview = {
        enabled = true,
      },
      keymaps = {
        focus_preview = "<C-l>",
        focus_list = "<C-w>",
      },
    },
    config = function(_, opts)
      require("fff").setup(opts)
      setup_input_focus_keymaps()
    end,
    keys = {
      { "ff", find_files(root_dir), desc = "FFFind files" },
      { "fg", live_grep(root_dir), desc = "LiFFFe grep" },
      {
        "fz",
        live_grep(root_dir, { grep = { modes = { "fuzzy", "plain" } } }),
        desc = "Live fffuzy grep",
      },
      {
        "fc",
        function()
          require("fff").live_grep({ cwd = root_dir(), query = vim.fn.expand("<cword>") })
        end,
        desc = "Search current word",
      },
      { "<leader>/", live_grep(root_dir), desc = "Grep (Root Dir)" },
      { "<leader><space>", find_files(root_dir), desc = "Find Files (Root Dir)" },
      { "<leader>ff", find_files(root_dir), desc = "Find Files (Root Dir)" },
      { "<leader>fF", find_files(cwd), desc = "Find Files (cwd)" },
      { "<leader>sg", live_grep(root_dir), desc = "Grep (Root Dir)" },
      { "<leader>sG", live_grep(cwd), desc = "Grep (cwd)" },
      {
        "<leader>sw",
        function()
          require("fff").live_grep({ cwd = root_dir(), query = visual_or_cword() })
        end,
        desc = "Visual selection or word (Root Dir)",
        mode = { "n", "x" },
      },
      {
        "<leader>sW",
        function()
          require("fff").live_grep({ cwd = cwd(), query = visual_or_cword() })
        end,
        desc = "Visual selection or word (cwd)",
        mode = { "n", "x" },
      },
    },
  },
}
