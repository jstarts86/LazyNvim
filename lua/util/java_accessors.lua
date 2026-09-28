---Record-style accessor generation (`name()` rather than `getName()`) for Java.
---
---jdtls's "Generate Getters" comes from Eclipse JDT and always uses the
---get/is prefix, with no preference to change it. Code actions can only come
---from an LSP server, so this is a tiny in-process one: no child process, no
---RPC — `cmd` is a Lua function and every request is answered from the
---buffer's existing treesitter tree. Its actions land in the same
---`<leader>ca` picker as jdtls's.

local M = {}

local NAME = "java-accessors"
local KIND = "source.generate.recordAccessors"
local COMMAND = "java-accessors.generate"

--------------------------------------------------------------------------------

---@param bufnr integer
---@param row integer 0-based
---@param col integer 0-based byte column
---@return TSNode|nil class_declaration enclosing the position
local function enclosing_class(bufnr, row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "java")
  if not ok or not parser then
    return nil
  end
  local node = parser:parse()[1]:root():named_descendant_for_range(row, col, row, col)
  while node and node:type() ~= "class_declaration" do
    node = node:parent()
  end
  return node
end

---@param node TSNode
---@return boolean
local function is_static(node, bufnr)
  for child in node:iter_children() do
    if child:type() == "modifiers" then
      return vim.treesitter.get_node_text(child, bufnr):find("%f[%w]static%f[%W]") ~= nil
    end
  end
  return false
end

---@class JavaAccessorField
---@field name string
---@field type string
---@field node TSNode the field_declaration

---Instance fields of the class that don't already have a zero-arg method of
---the same name.
---@param class TSNode
---@param bufnr integer
---@return JavaAccessorField[]
local function missing_accessors(class, bufnr)
  local body = class:field("body")[1]
  if not body then
    return {}
  end
  local text = function(n)
    return vim.treesitter.get_node_text(n, bufnr)
  end

  local existing, fields = {}, {}
  for member in body:iter_children() do
    local kind = member:type()
    if kind == "method_declaration" then
      local params = member:field("parameters")[1]
      if params and params:named_child_count() == 0 then
        existing[text(member:field("name")[1])] = true
      end
    elseif kind == "field_declaration" and not is_static(member, bufnr) then
      local type = text(member:field("type")[1])
      -- `int x, y;` has one declarator per name.
      for _, decl in ipairs(member:field("declarator")) do
        -- `int[] a` vs `int a[]`: C-style array dims hang off the declarator.
        local dims = decl:field("dimensions")[1]
        fields[#fields + 1] = {
          name = text(decl:field("name")[1]),
          type = type .. (dims and text(dims) or ""),
          node = member,
        }
      end
    end
  end

  return vim.tbl_filter(function(f)
    return not existing[f.name]
  end, fields)
end

---Row to insert before, for a cursor at `row`: right after the member the
---cursor is in, or at the cursor line itself when it sits between members.
---nil when the cursor is on a field or outside the body (e.g. on the class
---header), or the body has no line of its own to insert on.
---@param body TSNode class_body
---@param row integer 0-based cursor row
---@return integer|nil
local function cursor_row(body, row)
  local body_start, _, body_end = body:range()
  if row <= body_start or row >= body_end then
    return nil
  end
  for member in body:iter_children() do
    -- Comments don't count: inserting after a javadoc would orphan it.
    if member:named() and not member:type():find("comment") then
      local s, _, e = member:range()
      if row >= s and row <= e then
        -- On a field: don't split the field block, use the class end instead.
        return member:type() ~= "field_declaration" and e + 1 or nil
      end
    end
  end
  return row
end

---A TextEdit inserting `fields`' accessors, one line each, at the cursor
---(see cursor_row) or else just before the class's closing brace.
---@param class TSNode
---@param fields JavaAccessorField[]
---@param bufnr integer
---@param row integer 0-based cursor row
---@return lsp.TextEdit
local function insert_edit(class, fields, bufnr, row)
  local unit = vim.bo[bufnr].expandtab and string.rep(" ", vim.fn.shiftwidth()) or "\t"
  local class_row = class:start()
  local base = vim.api.nvim_buf_get_lines(bufnr, class_row, class_row + 1, false)[1]:match("^%s*")
  local ind = base .. unit

  local methods = {}
  for _, f in ipairs(fields) do
    methods[#methods + 1] = ("%spublic %s %s() { return %s; }\n"):format(ind, f.type, f.name, f.name)
  end
  local block = table.concat(methods)

  local body = class:field("body")[1]
  local _, _, end_row, end_col = body:range()
  local brace_col = end_col - 1
  local line_at = function(r)
    return r >= 0 and vim.api.nvim_buf_get_lines(bufnr, r, r + 1, false)[1] or ""
  end

  local at = cursor_row(body, row)
  if not at and line_at(end_row):sub(1, brace_col):match("^%s*$") then
    at = end_row -- `}` on its own line
  end
  if at then
    -- Insert whole lines before `at`, padded with a blank line on each side
    -- unless one is already there or the neighbour is the body's own brace.
    local prev, next = line_at(at - 1), line_at(at)
    local lead = (prev:match("^%s*$") or prev:match("{%s*$")) and "" or "\n"
    local trail = (next:match("^%s*$") or next:match("^%s*}")) and "" or "\n"
    local pos = { line = at, character = 0 }
    return { range = { start = pos, ["end"] = pos }, newText = lead .. block .. trail }
  end

  -- One-line body (`class A { int x; }`): break it open, swallowing the
  -- whitespace before `}` so no trailing space is left behind.
  local before = line_at(end_row):sub(1, brace_col)
  return {
    range = {
      start = { line = end_row, character = #before:gsub("%s+$", "") },
      ["end"] = { line = end_row, character = brace_col },
    },
    newText = "\n\n" .. block .. base,
  }
end

---@param params lsp.CodeActionParams
---@return lsp.CodeAction[]
local function code_actions(params)
  local uri = params.textDocument.uri
  local bufnr = vim.uri_to_bufnr(uri)
  local row, col = params.range.start.line, params.range.start.character
  local class = enclosing_class(bufnr, row, col)
  if not class then
    return {}
  end
  local fields = missing_accessors(class, bufnr)
  if #fields == 0 then
    return {}
  end

  local function action(title, subset)
    return {
      title = title,
      kind = KIND,
      edit = { changes = { [uri] = { insert_edit(class, subset, bufnr, row) } } },
    }
  end

  local actions = {}
  -- Cursor on a field declaration: offer just that field's accessor(s) first.
  local here = vim.tbl_filter(function(f)
    local s, _, e = f.node:range()
    return row >= s and row <= e
  end, fields)
  if #here > 0 and #here < #fields then
    local names = table.concat(vim.tbl_map(function(f) return f.name .. "()" end, here), ", ")
    actions[#actions + 1] = action("Generate accessor " .. names, here)
  end
  -- Like jdtls's "Generate Getters...": no edit up front, a client-side
  -- command that asks which fields once the action is chosen.
  actions[#actions + 1] = {
    title = "Generate accessors...",
    kind = KIND,
    command = { title = "Generate accessors...", command = COMMAND, arguments = { uri, row, col } },
  }
  return actions
end

---Client-side handler for the "Generate accessors..." action: pick fields
---with the same prompt nvim-jdtls uses for constructors, then insert.
---@param command lsp.Command
local function generate(command)
  local uri, row, col = unpack(command.arguments)
  local bufnr = vim.uri_to_bufnr(uri)
  local class = enclosing_class(bufnr, row, col)
  local fields = class and missing_accessors(class, bufnr) or {}
  if #fields == 0 then
    return
  end

  local ok, ui = pcall(require, "jdtls.ui")
  local picked = ok
      and ui.pick_many(fields, "Include field(s) to generate accessors for:", function(f)
        return f.name .. ": " .. f.type
      end, { is_selected = function() return true end })
    or fields
  if #picked == 0 then
    return
  end
  -- pick_many returns fields in toggle order; keep declaration order.
  local chosen = {}
  for _, f in ipairs(picked) do
    chosen[f] = true
  end
  picked = vim.tbl_filter(function(f) return chosen[f] end, fields)

  vim.lsp.util.apply_workspace_edit({ changes = { [uri] = { insert_edit(class, picked, bufnr, row) } } }, "utf-8")
end

--------------------------------------------------------------------------------

---In-process server: `vim.lsp.start` accepts a function as `cmd` and talks to
---the table it returns instead of spawning anything.
local function server(dispatchers)
  local closing, id = false, 0
  return {
    request = function(method, params, callback)
      id = id + 1
      local result
      if method == "initialize" then
        result = { capabilities = { codeActionProvider = true, positionEncoding = "utf-8" } }
      elseif method == "textDocument/codeAction" then
        local ok, res = pcall(code_actions, params)
        result = ok and res or {}
      end
      -- Reply asynchronously: the client registers the request id only after
      -- request() returns, so a synchronous reply would leave it "pending".
      vim.schedule(function()
        callback(nil, result)
      end)
      return true, id
    end,
    notify = function(method)
      if method == "exit" then
        closing = true
        dispatchers.on_exit(0, 15)
      end
      return true
    end,
    is_closing = function()
      return closing
    end,
    terminate = function()
      closing = true
    end,
  }
end

---@param bufnr integer
function M.attach(bufnr)
  -- No root_dir: one client serves every Java buffer this session.
  vim.lsp.start({ name = NAME, cmd = server, commands = { [COMMAND] = generate } }, { bufnr = bufnr })
end

return M
