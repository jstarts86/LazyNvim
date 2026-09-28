---Run the current Java file with the enclosing project's classpath and JDK.
---
---`java Foo.java` (single-file source launch) only sees the JDK's own classes,
---so any file referencing a sibling type — or a dependency — fails to compile.
---This asks jdtls for the same classpath and java executable it hands the
---debugger (`vscode.java.resolveClasspath` / `vscode.java.resolveJavaExecutable`,
---provided by the java-debug-adapter bundle wired up in lua/plugins/java.lua)
---and runs the file against those.
---
---Source launch is kept rather than executing the already-compiled class from
---`bin/main`: the JDK compiles the buffer's own source in memory and that copy
---shadows the stale `.class` of the same name on the classpath, so the file
---always runs as written even if jdtls's incremental build hasn't caught up.
---Everything else still resolves from the classpath.

local M = {}

--------------------------------------------------------------------------------

local java_major = {} ---@type table<string, string> java executable -> major

---Major version of a JDK, for `--source`. Cached; this shells out.
---@param exe string
---@return string
local function major_of(exe)
  if not java_major[exe] then
    local out = vim.system({ exe, "-version" }, { text = true }):wait() -- prints to stderr
    local version = ((out.stderr or "") .. (out.stdout or "")):match('version "([%d._]+)"') or ""
    local first, second = version:match("^(%d+)%.(%d+)")
    -- Legacy scheme: 1.8.0_402 is Java 8.
    java_major[exe] = (first == "1" and second) or version:match("^(%d+)") or "21"
  end
  return java_major[exe]
end

---@param client vim.lsp.Client
---@param command string
---@return boolean
local function supports(client, command)
  local provider = client.server_capabilities.executeCommandProvider or {}
  return vim.tbl_contains(provider.commands or {}, command)
end

--------------------------------------------------------------------------------

---Build the shell command to run `bufnr`'s file in project context.
---Runs inside a coroutine: jdtls.util.execute_command yields when given no
---callback, which keeps four dependent LSP round-trips readable as straight
---line code instead of a callback pyramid.
---@param client vim.lsp.Client
---@param bufnr integer
---@return string|nil command, string|nil err
local function build(client, bufnr)
  local util = require("jdtls.util")

  -- Package + class name of the buffer, e.g. com.start2save.domain.user.Email.
  local mainclass = util.resolve_classname()
  if not mainclass or mainclass == "" then
    return nil, "could not determine the class name of this buffer"
  end

  -- resolveClasspath needs a project to scope against. resolveMainClass lists
  -- every runnable class jdtls has indexed; ours is in there iff it has a main.
  local err, mainclasses = util.execute_command({ command = "vscode.java.resolveMainClass" }, nil, bufnr)
  if err then
    return nil, "resolveMainClass: " .. (err.message or vim.inspect(err))
  end
  local project
  for _, entry in ipairs(mainclasses or {}) do
    if entry.mainClass == mainclass then
      project = entry.projectName
      break
    end
  end
  if not project then
    -- Almost always the real cause, and the message jdtls gives instead is
    -- an opaque empty classpath.
    return nil, mainclass .. " has no main method (or jdtls has not indexed it yet)"
  end

  -- The project's JDK, not whatever `java` is on PATH: a Gradle/Maven toolchain
  -- routinely differs from the shell's, and running newer classes on an older
  -- JVM fails with UnsupportedClassVersionError.
  local java_exec = "java"
  if supports(client, "vscode.java.resolveJavaExecutable") then
    local jerr, exe = util.execute_command({
      command = "vscode.java.resolveJavaExecutable",
      arguments = { mainclass, project },
    }, nil, bufnr)
    if not jerr and exe and exe ~= "" then
      java_exec = exe
    end
  end

  local cerr, paths = util.execute_command({
    command = "vscode.java.resolveClasspath",
    arguments = { mainclass, project },
  }, nil, bufnr)
  if cerr then
    return nil, "resolveClasspath: " .. (cerr.message or vim.inspect(cerr))
  end
  -- Drop entries that do not exist yet; a stale one aborts the launch. Same
  -- filter nvim-jdtls applies before handing the list to the debug adapter.
  local function existing(list)
    return vim.tbl_filter(function(entry)
      return vim.fn.isdirectory(entry) == 1 or vim.fn.filereadable(entry) == 1
    end, list or {})
  end
  local modulepath = existing(paths and paths[1]) -- non-empty only for JPMS projects
  local classpath = existing(paths and paths[2])
  if vim.tbl_isempty(modulepath) and vim.tbl_isempty(classpath) then
    return nil, "empty classpath — the project may have compile errors or unresolved dependencies"
  end

  local args = { vim.fn.shellescape(java_exec) }

  -- Only pass --enable-preview when the project itself compiles with it;
  -- forcing it on a project that does not would change how the file compiles.
  -- In source-launch mode --enable-preview is rejected without --source.
  if supports(client, "vscode.java.checkProjectSettings") then
    local perr, preview = util.execute_command({
      command = "vscode.java.checkProjectSettings",
      arguments = vim.fn.json_encode({
        className = mainclass,
        projectName = project,
        inheritedOptions = true,
        expectedOptions = { ["org.eclipse.jdt.core.compiler.problem.enablePreviewFeatures"] = "enabled" },
      }),
    }, nil, bufnr)
    if not perr and preview then
      vim.list_extend(args, { "--enable-preview", "--source", major_of(java_exec) })
    end
  end

  -- A JPMS project puts its dependencies on the module path. Source launch
  -- compiles the buffer into the *unnamed* module, which does not read those
  -- modules by default, so passing --module-path alone still fails to compile
  -- with "package ... does not exist"; ALL-MODULE-PATH promotes every module
  -- on the path to the root set and the imports resolve. Verified against a
  -- modular test project. Empty for the ordinary non-modular project, where
  -- jdtls returns everything on the classpath instead.
  if not vim.tbl_isempty(modulepath) then
    vim.list_extend(args, {
      "--module-path",
      vim.fn.shellescape(table.concat(modulepath, ":")),
      "--add-modules",
      "ALL-MODULE-PATH",
    })
  end
  if not vim.tbl_isempty(classpath) then
    vim.list_extend(args, { "-cp", vim.fn.shellescape(table.concat(classpath, ":")) })
  end
  args[#args + 1] = vim.fn.shellescape(vim.api.nvim_buf_get_name(bufnr))

  return table.concat(args, " ")
end

--------------------------------------------------------------------------------

---@param bufnr integer?
---@return boolean handled false when no jdtls client owns the buffer
function M.run(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]
  if not client then
    return false
  end

  -- The buffer is the thing being compiled, so it has to be on disk first.
  vim.cmd("silent! update")

  coroutine.wrap(function()
    local cmd, err = build(client, bufnr)
    if not cmd then
      vim.notify("Java run: " .. err, vim.log.levels.ERROR)
      return
    end
    -- Reuse code_runner's terminal so :RunClose and the window layout behave
    -- the same as every other <leader>R. Its lazy `keys` stub never fires here
    -- (the buffer-local mapping shadows it), hence the explicit load.
    require("lazy").load({ plugins = { "code_runner.nvim" } })
    require("code_runner").run_from_fn("cd $dir && " .. cmd)
  end)()

  return true
end

return M
