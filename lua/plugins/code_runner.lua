-- code_runner.nvim — one-key run for the current file or project.
--
-- :RunCode resolves in this order (code_runner/commands.lua run_code):
--   1. a `project` entry whose root is a prefix of the current file's path
--   2. `root_markers`, searched upward from the file — pom.xml / build.gradle
--   3. the `filetype` command for the buffer
--
-- So inside a Maven or Gradle project <leader>rr runs the build tool, and only a
-- standalone .java file falls through to the single-file launcher below.
-- <leader>rR (:RunFile) skips steps 1-2 and always runs the current buffer,
-- which is what you want for one-off classes living inside a real project.
--
-- Both sit under <leader>r rather than on it: the editor.refactoring extra
-- claims bare <leader>r as a which-key group (an empty "" mapping, in normal
-- and visual mode) and util.rest claims <leader>R, and those placeholders
-- resolve after lazy's key stubs, so a mapping on either would never fire.
-- lua/plugins/java.lua rebinds <leader>rR buffer-locally where jdtls attaches.

--------------------------------------------------------------------------------
-- Source level
--------------------------------------------------------------------------------

local source_level ---@type string|nil

---Major version of the `java` on PATH, for `--source`.
---
---Needed because `--enable-preview` is rejected in source-file mode unless
---`--source` is given explicitly ("error: --enable-preview must be used with
-----source"). Cached: this shells out, and <leader>rr is a hot key.
---@return string
local function java_source()
  if source_level then
    return source_level
  end
  -- `java -version` writes to stderr, hence the merge.
  local out = vim.system({ "java", "-version" }, { text = true }):wait()
  local version = ((out.stderr or "") .. (out.stdout or "")):match('version "([%d._]+)"')
  local first, second = (version or ""):match("^(%d+)%.(%d+)")
  -- Legacy scheme: 1.8.0_402 is Java 8. Source-file launch needs 11+ anyway,
  -- so this only keeps us from emitting a nonsense `--source 1`.
  source_level = (first == "1" and second) or version and version:match("^(%d+)") or "21"
  return source_level
end

--------------------------------------------------------------------------------

---Write the buffer before running so the terminal never executes stale code.
---Done here rather than through `before_run_filetype`, which code_runner only
---calls on the filetype path — never when a project/root marker matched.
---@param cmd string
local function run(cmd)
  return function()
    vim.cmd("silent! update")
    vim.cmd(cmd)
  end
end

return {
  "CRAG666/code_runner.nvim",
  cmd = { "RunCode", "RunFile", "RunProject", "RunClose" },
  keys = {
    { "<leader>rr", run("RunCode"), desc = "Run code (project or file)" },
    { "<leader>rR", run("RunFile"), desc = "Run current file" },
  },
  opts = {
    filetype = {
      java = function()
        -- Single-file source-code launch (JDK 11+). Preferred over the plugin's
        -- default `cd $dir && javac $fileName && java $fileNameWithoutExt`,
        -- which drops .class files next to the source and breaks outright when
        -- the file declares a package — `java Foo` needs the FQN there, and the
        -- cwd is wrong for it. Matches the flags used by scratch-runner in
        -- lua/plugins/scratch.lua.
        --
        -- `cd $dir` first so the program's own relative paths resolve against
        -- the file's directory rather than Neovim's cwd.
        return { "cd $dir &&", "java --enable-preview --source", java_source(), "$file" }
      end,
      javascript = "node",
      python = "python3 -u",
      sh = "bash",
    },

    -- Restated in full rather than partially: options.set() merges user options
    -- with vim.tbl_deep_extend("force", ...), which for a list merges by index —
    -- a shorter user list would leave the tail of the defaults behind it.
    root_markers = {
      { "pom.xml", "mvn -q compile exec:java" },
      { "build.gradle", "./gradlew run" },
      { "build.gradle.kts", "./gradlew run" }, -- Kotlin DSL; not a plugin default
      { "Cargo.toml", "cargo run" },
      { "go.mod", "go run ." },
      { "package.json", "npm start" },
      { "Makefile", "make" },
      { "CMakeLists.txt", "cmake -B build && cmake --build build" },
    },

    mode = "term",
    term = { position = "bot", size = 15 },
    focus = false,
    startinsert = false,
  },
}
