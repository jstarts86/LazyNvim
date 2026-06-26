local function get_package()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then return "" end
  local dir = vim.fn.fnamemodify(bufname, ":h")
  if dir == "" then return "" end

  for _, root in ipairs({ "/src/main/java/", "/src/test/java/", "/src/main/kotlin/", "/src/test/kotlin/" }) do
    local s, e = dir:find(root, 1, true)
    if s then
      local sub = dir:sub(e + 1)
      if sub ~= "" then
        return "package " .. sub:gsub("/", ".") .. ";\n\n"
      end
    end
  end

  local current = dir
  while current ~= "" and current ~= "/" do
    local files = vim.fn.glob(current .. "/*.java", false, true)
    if #files > 0 then
      for _, f in ipairs(files) do
        for _, line in ipairs(vim.fn.readfile(f, "", 20)) do
          local pkg = line:match("^%s*package%s+([%w%.]+)%s*;")
          if pkg then
            local pkg_dir = current .. "/" .. pkg:gsub("%.", "/")
            if vim.fn.isdirectory(pkg_dir) == 1 and dir:find(pkg_dir, 1, true) == 1 then
              local rel = dir:sub(#pkg_dir + 2)
              if rel ~= "" then
                return "package " .. pkg .. "." .. rel:gsub("/", ".") .. ";\n\n"
              end
              return "package " .. pkg .. ";\n\n"
            end
          end
        end
      end
      break
    end
    current = vim.fn.fnamemodify(current, ":h")
  end

  return ""
end

local function class_name()
  local base = vim.fn.expand("%:t:r")
  if base == "" then return "MyClass" end
  local name = base:gsub("[^%w]", "")
  if name == "" then name = "MyClass" end
  return name:sub(1, 1):upper() .. name:sub(2)
end

return {
  s({ trig = "class", desc = "public class (with package)" }, fmt(
    "{}public class {} {{\n\t{}\n}}",
    {
      f(function() return get_package() end, {}),
      f(function() return class_name() end, {}),
      i(0),
    }
  )),
  s({ trig = "interface", desc = "public interface (with package)" }, fmt(
    "{}public interface {} {{\n\t{}\n}}",
    {
      f(function() return get_package() end, {}),
      f(function() return class_name() end, {}),
      i(0),
    }
  )),
  s({ trig = "enum", desc = "public enum (with package)" }, fmt(
    "{}public enum {} {{\n\t{}\n}}",
    {
      f(function() return get_package() end, {}),
      f(function() return class_name() end, {}),
      i(0),
    }
  )),
  s({ trig = "record", desc = "public record (with package)" }, fmt(
    "{}public record {}() {{\n\t{}\n}}",
    {
      f(function() return get_package() end, {}),
      f(function() return class_name() end, {}),
      i(0),
    }
  )),
}
