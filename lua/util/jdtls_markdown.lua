-- Shared cleanup for jdtls hover markdown.
--
-- jdtls renders cross-references as markdown links to `jdt://` URIs, which are
-- long, unclickable, and blow out the width of any table they appear in. Two
-- call sites need the same fix:
--   * lua/config/autocmds.lua patches noice.lsp.format.format_markdown, which is
--     where hover content flows for every non-java server and for java when the
--     default `vim.lsp.buf.hover` is used.
--   * lua/plugins/java.lua's custom `K` handler, which builds its own focusable
--     float and so bypasses noice entirely.
--
-- (after/ftplugin/markdown.lua also conceals `jdt://` via a syntax match. That is
-- a display-layer fallback on a different surface and is left alone.)

local M = {}

-- Placeholders for backslash-escaped brackets while the link pattern runs.
-- jdtls escapes brackets inside link labels, so any Java array type arrives as
-- `[run(Class, String \[\])](jdt://...)`. A naive `%[([^%]]+)%]` stops at the
-- `]` inside `\]` and never matches, which is why array-bearing signatures used
-- to render with the raw URL still in them. Swapping the escaped pairs out
-- first makes the label unambiguous; they are swapped back afterwards so the
-- markdown stays valid.
local ESC_OPEN, ESC_CLOSE = "\1", "\2"

---Strip a `[label](jdt://...)` markdown link down to just `label`.
---@param line string
---@return string
local function strip_jdt_links(line)
  if not line:find("jdt://", 1, true) then
    return line
  end
  line = line:gsub("\\%[", ESC_OPEN):gsub("\\%]", ESC_CLOSE)
  -- The URL is percent-encoded by jdtls (`(` -> %28), so it never contains a
  -- literal ")" and [^%)]* is safe as the href matcher.
  line = line:gsub("%[([^%]]+)%]%(jdt://[^%)]*%)", "%1")
  return (line:gsub(ESC_OPEN, "\\["):gsub(ESC_CLOSE, "\\]"))
end

---Re-pad markdown table cells to a single leading/trailing space.
---Column widths were sized around the now-removed URLs, so without this the
---table renders with huge ragged gaps.
---@param line string
---@return string
local function normalize_table_row(line)
  if line:sub(1, 1) ~= "|" then
    return line
  end
  local cells = vim.split(line, "|", { plain = true })
  for i, cell in ipairs(cells) do
    local trimmed = vim.trim(cell)
    -- Leave separator rows (all dashes/colons) alone so the table stays valid.
    cells[i] = (trimmed == "" or trimmed:match("^[%-:]+$")) and cell or (" " .. trimmed .. " ")
  end
  return table.concat(cells, "|")
end

---Clean a list of markdown lines in place and return it.
---@param lines string[]
---@return string[]
function M.clean(lines)
  for i, line in ipairs(lines) do
    lines[i] = normalize_table_row(strip_jdt_links(line))
  end
  return lines
end

return M
