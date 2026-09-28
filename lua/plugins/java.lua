-- Java / jdtls — deltas on top of `lazyvim.plugins.extras.lang.java`.
--
-- The extra owns start/attach, the per-project `-configuration` and `-data`
-- dirs, lombok, capabilities, DAP wiring (`setup_dap`), the test keymaps and
-- the which-key groups. This file only supplies what differs.
--
-- Do NOT add a `config` function here. lazy.nvim resolves `config`
-- last-writer-wins, so ours would silently replace the extra's and take
-- `require("jdtls").setup_dap()` with it — leaving `dap.adapters.java` nil and
-- every test keymap dead at launch. Extend through `opts` instead; function
-- `opts` chain, so ours receives the extra's table (lazy/core/plugin.lua:458).

local uv = vim.uv

--------------------------------------------------------------------------------
-- JDK discovery
--------------------------------------------------------------------------------

-- Searched in order; the first root to supply a given major version wins.
local JDK_ROOTS = {
  vim.fn.expand("~/.sdkman/candidates/java"),
  vim.fn.expand("~/Library/Java/JavaVirtualMachines"),
  "/Library/Java/JavaVirtualMachines",
}

---Major version from a `JAVA_VERSION` string ("21.0.9" -> 21, "1.8.0_402" -> 8).
---@param version string
---@return integer|nil
local function parse_major(version)
  local first, second = version:match("^(%d+)%.(%d+)")
  if first == "1" and second then
    return tonumber(second)
  end
  return tonumber(version:match("^(%d+)"))
end

---Read the major version out of a JDK home's `release` file.
---@param home string
---@return integer|nil
local function jdk_major(home)
  local file = io.open(home .. "/release", "r")
  if not file then
    return nil
  end
  local major
  for line in file:lines() do
    local version = line:match('^JAVA_VERSION="([%d._]+)"')
    if version then
      major = parse_major(version)
      break
    end
  end
  file:close()
  return major
end

---@return table<integer, string> major version -> java home
local function discover_jdks()
  local found = {}
  for _, root in ipairs(JDK_ROOTS) do
    local names = {}
    local dir = uv.fs_scandir(root)
    while dir do
      local name = uv.fs_scandir_next(dir)
      if not name then
        break
      end
      if name ~= "current" then -- sdkman's symlink to the active JDK
        names[#names + 1] = name
      end
    end
    -- fs_scandir order is filesystem-dependent; sort so that a root holding two
    -- builds of the same major (21.0.9-oracle and 21.0.9-tem) always picks the
    -- same one instead of varying between runs.
    table.sort(names)

    for _, name in ipairs(names) do
      -- sdkman lays JDKs out flat; macOS bundles nest under Contents/Home.
      for _, home in ipairs({ root .. "/" .. name, root .. "/" .. name .. "/Contents/Home" }) do
        local major = uv.fs_stat(home .. "/release") and jdk_major(home)
        if major and not found[major] then
          found[major] = home
        end
      end
    end
  end
  return found
end

local jdks ---@type table<integer, string>|nil
local majors ---@type integer[]|nil

local function jdk_index()
  if not jdks then
    jdks = discover_jdks()
    majors = vim.tbl_keys(jdks)
    table.sort(majors)
  end
  return jdks, majors
end

---jdtls `settings.java.configuration.runtimes`, discovered rather than
---hardcoded so a patch bump (25.0.1-tem -> 25.0.2-tem) doesn't silently break
---the config. Newest installed JDK becomes the default.
local function jdk_runtimes()
  local homes, sorted = jdk_index()
  local newest = sorted[#sorted]
  local runtimes = {}
  for _, major in ipairs(sorted) do
    runtimes[#runtimes + 1] = {
      -- Execution environments below 9 are named "JavaSE-1.x".
      name = major >= 9 and ("JavaSE-" .. major) or ("JavaSE-1." .. major),
      path = homes[major],
      default = major == newest or nil,
    }
  end
  return runtimes
end

---The JDK jdtls itself runs on. Newest wins; jdtls happily targets older
---release levels via the `runtimes` list above.
local function default_jdk()
  local homes, sorted = jdk_index()
  return homes[sorted[#sorted]]
end

--------------------------------------------------------------------------------
-- OSGi bundles
--------------------------------------------------------------------------------

-- jdtls 1.60 ships ASM 9.10.1, but com.microsoft.java.test.plugin 0.43.1
-- declares Require-Bundle org.objectweb.asm [9.9.0,9.10.0) and org.jacoco.core
-- imports org.objectweb.asm{,.commons,.tree} at [9.9.0,9.10). Neither range can
-- be satisfied by jdtls's own copy, so both bundles fail to resolve and every
-- vscode.java.test.* command disappears — no test discovery, no test running.
--
-- Supplying ASM 9.9 as extra bundles fixes it: OSGi hosts 9.9 and 9.10.1 side
-- by side and wires each consumer to the version matching its range.
--
-- Still required as of 2026-08-28 (re-verified against the JAR manifests and
-- the Mason registry).
--
-- Note: the first jdtls start against a fresh configuration area still reports
-- these bundles as unresolved — Equinox snapshots its resolution before the
-- externally-supplied jars are available. They resolve on the second start.
-- After wiping ~/.cache/nvim/jdtls, restart nvim once before concluding the
-- test commands are broken. See docs/jdtls-asm-bundles.md.
local ASM_VERSION = "9.9"
local ASM_ARTIFACTS = { "asm", "asm-commons", "asm-tree" }

local asm_cache ---@type string[]|nil

---@return string[]
local function asm_bundles()
  if asm_cache then
    return asm_cache
  end

  local dir = vim.fn.stdpath("data") .. "/jdtls-asm-bundles"
  local jars, missing = {}, {}
  for _, artifact in ipairs(ASM_ARTIFACTS) do
    local jar = ("%s/%s-%s.jar"):format(dir, artifact, ASM_VERSION)
    if uv.fs_stat(jar) then
      jars[#jars + 1] = jar
    else
      missing[#missing + 1] = artifact
    end
  end

  if #missing > 0 then
    -- Blocking on purpose: the bundle list must be complete before jdtls
    -- starts, and this runs once — the jars are cached on disk afterwards.
    vim.fn.mkdir(dir, "p")
    vim.notify(
      ("jdtls: fetching ASM %s bundles (%s)"):format(ASM_VERSION, table.concat(missing, ", ")),
      vim.log.levels.INFO
    )
    local failed = {}
    for _, artifact in ipairs(missing) do
      local jar = ("%s/%s-%s.jar"):format(dir, artifact, ASM_VERSION)
      local url = ("https://repo1.maven.org/maven2/org/ow2/asm/%s/%s/%s-%s.jar")
        :format(artifact, ASM_VERSION, artifact, ASM_VERSION)
      local result = vim.system({ "curl", "-sfLo", jar, url }, { timeout = 30000 }):wait()
      if result.code == 0 and uv.fs_stat(jar) then
        jars[#jars + 1] = jar
      else
        failed[#failed + 1] = artifact
        pcall(uv.fs_unlink, jar) -- never leave a truncated jar for OSGi to choke on
      end
    end
    if #failed > 0 then
      vim.notify(
        ("jdtls: could not fetch ASM %s (%s).\nJava test commands will be unavailable — see docs/jdtls-asm-bundles.md")
          :format(ASM_VERSION, table.concat(failed, ", ")),
        vim.log.levels.ERROR
      )
    end
  end

  if #jars == #ASM_ARTIFACTS then
    asm_cache = jars -- only memoize a complete set, so a later restart can retry
  end
  return jars
end

---@param name string basename of a jar in java-test's server/ dir
---@return boolean skip
local function skip_test_jar(name)
  -- Not valid OSGi bundles; including either aborts the whole bundle load
  -- rather than just its own. Upstream's package.json omits them too.
  return name:find("runner-jar-with-dependencies", 1, true) ~= nil or name == "jacocoagent.jar"
end

local bundle_cache ---@type string[]|nil

---java-debug-adapter + java-test + ASM, as absolute jar paths.
---@return string[]
local function bundles()
  if bundle_cache then
    return bundle_cache
  end

  local mason = vim.env.MASON
  if not mason or mason == "" then
    mason = vim.fn.stdpath("data") .. "/mason"
  end

  local jars =
    vim.fn.glob(mason .. "/share/java-debug-adapter/com.microsoft.java.debug.plugin-*.jar", false, true)

  -- Glob packages/ rather than share/: share/java-test carries an unversioned
  -- com.microsoft.java.test.plugin.jar alias pointing at the same file as the
  -- versioned one, and handing OSGi the same bundle twice under two paths
  -- invites resolution failures.
  for _, jar in ipairs(vim.fn.glob(mason .. "/packages/java-test/extension/server/*.jar", false, true)) do
    local name = vim.fs.basename(jar)
    if not skip_test_jar(name) then
      jars[#jars + 1] = jar
    end
  end

  vim.list_extend(jars, asm_bundles())
  bundle_cache = jars
  return jars
end

--------------------------------------------------------------------------------
-- Hover
--------------------------------------------------------------------------------

-- LazyVim's default K is `vim.lsp.buf.hover()`, which noice renders in a float
-- you cannot enter. jdtls docs are full of cross-references worth chasing, so
-- Java gets a focusable float instead:
--
--   K       show the docs, cursor stays in the source buffer
--   K again jump into the float (<C-w>w still works too)
--   gd      inside the float, look up the symbol under the cursor
--   q       close it
--   <C-f>/<C-b>  scroll the float without leaving the source window
--
-- The second press is handled here rather than via open_floating_preview's
-- `focus_id`, which would re-issue the whole hover request before focusing.
local function hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "jdtls" })[1]
  if not client then
    return vim.lsp.buf.hover()
  end

  -- Second press: the float from the last one is still up, so enter it.
  -- Moving the cursor closes the float (CursorMoved is in close_events), so an
  -- invalid handle here just means we should fetch fresh docs.
  local open = vim.b[bufnr].jdtls_hover_win
  if open and vim.api.nvim_win_is_valid(open) then
    vim.api.nvim_set_current_win(open)
    return
  end

  local src_win = vim.api.nvim_get_current_win()
  local src_cursor = vim.api.nvim_win_get_cursor(src_win)
  local params = vim.lsp.util.make_position_params(src_win, client.offset_encoding)

  client:request("textDocument/hover", params, function(err, result)
    if err or not result or not result.contents then
      return
    end

    local md = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
    local lines = vim.split(table.concat(md, "\n"), "\n", { trimempty = true })
    if vim.tbl_isempty(lines) then
      return
    end
    -- Shared with the noice patch in lua/config/autocmds.lua.
    lines = require("util.jdtls_markdown").clean(lines)

    local float_buf, float_win = vim.lsp.util.open_floating_preview(lines, "markdown", {
      focusable = true,
      focus = false, -- first press never steals the cursor
      border = "rounded",
    })
    vim.b[bufnr].jdtls_hover_win = float_win

    -- <C-f>/<C-b> scroll the float while the cursor stays in the source
    -- window, matching the noice hover keymaps in config/keymaps.lua. This
    -- float is not noice-managed, so noice.lsp.scroll can't reach it — buffer
    -- -local expr maps do the same job, falling back to the native key when
    -- the float is gone (e.g. auto-closed by CursorMoved).
    local function scroll(n)
      local win = vim.b[bufnr].jdtls_hover_win
      if not win or not vim.api.nvim_win_is_valid(win) then
        return false
      end
      vim.api.nvim_win_call(win, function()
        vim.cmd(("normal! %d%s"):format(math.abs(n), n > 0 and "\005" or "\021"))
      end)
      return true
    end

    for _, key in ipairs({ "<c-f>", "<c-b>" }) do
      vim.keymap.set("n", key, function()
        if not scroll(key == "<c-f>" and 4 or -4) then
          return key
        end
        return ""
      end, { buffer = bufnr, nowait = true, silent = true, expr = true, desc = "Java: scroll hover doc" })
    end

    local function close()
      if vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_win_close(float_win, true)
      end
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.b[bufnr].jdtls_hover_win = nil
        for _, key in ipairs({ "<c-f>", "<c-b>" }) do
          pcall(vim.keymap.del, "n", key, { buffer = bufnr })
        end
      end
    end

    vim.keymap.set("n", "gd", function()
      local word = vim.fn.expand("<cword>")
      close()
      vim.api.nvim_set_current_win(src_win)
      vim.api.nvim_win_set_cursor(src_win, src_cursor)
      -- snacks is this config's picker (editor.snacks_picker extra).
      local ok = pcall(function()
        Snacks.picker.lsp_workspace_symbols({ search = word })
      end)
      if not ok then
        vim.lsp.buf.workspace_symbol(word)
      end
    end, { buffer = float_buf, nowait = true, desc = "Java: Workspace symbol under cursor" })

    vim.keymap.set("n", "q", close, { buffer = float_buf, nowait = true, desc = "Close hover" })
  end, bufnr)
end

--------------------------------------------------------------------------------
-- Running a single file
--------------------------------------------------------------------------------

---Run the buffer against the project's classpath and JDK, resolved through
---jdtls. See lua/util/java_run.lua for why that beats plain `java Foo.java`.
local function run_file()
  if not require("util.java_run").run() then
    vim.notify("jdtls is not attached to this buffer", vim.log.levels.WARN)
  end
end

--------------------------------------------------------------------------------

return {
  {
    "mfussenegger/nvim-jdtls",
    init = function()
      -- Registered from `init` rather than `opts` so the health check exists
      -- before the first java buffer, and so the release hook is in place even
      -- if the plugin never loads this session (release() is a no-op then).
      vim.api.nvim_create_user_command("JdtlsDoctor", function()
        require("util.jdtls_workspace").doctor()
      end, { desc = "Report jdtls clients, workspaces and index health" })

      -- Record-style `name()` accessors as a code action; jdtls only offers
      -- getX(). See lua/util/java_accessors.lua.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        desc = "Attach java-accessors code actions",
        callback = function(args)
          require("util.java_accessors").attach(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd("VimLeavePre", {
        desc = "Release jdtls workspace claims",
        callback = function()
          for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
            client:stop(true)
          end
          require("util.jdtls_workspace").release()
        end,
      })
    end,
    opts = function(_, opts)
      -- Default max heap is a quarter of physical RAM, which let a single
      -- server reach 4.3 GB here. GC pressure at that size makes a truncated
      -- index write — the failure this whole file guards against — likelier.
      if type(opts.cmd) == "table" then
        table.insert(opts.cmd, "--jvm-arg=-Xmx3G")
      end

      -- `vim.lsp.config.jdtls.root_markers` keeps `.git` in the same tier as
      -- `gradlew`/`mvnw` (nvim-lspconfig/lsp/jdtls.lua:53-64), and nvim-jdtls
      -- contributes a flat `{".git", "gradlew", "mvnw"}` of its own
      -- (nvim-jdtls/lsp/jdtls.lua:2). A module inside a monorepo can therefore
      -- resolve to the git root, which imports the same module a second time
      -- from a second Eclipse workspace — two servers, one source tree, both
      -- rewriting its metadata. Keep `.git` strictly last.
      opts.root_dir = function(path)
        return vim.fs.root(path, { "settings.gradle.kts", "settings.gradle" }) -- gradle build root
          or vim.fs.root(path, { "pom.xml", "build.gradle.kts", "build.gradle", "build.xml" })
          or vim.fs.root(path, { "gradlew", "mvnw", ".git" })
      end

      -- Never hand two jdtls JVMs the same `-data` dir. See
      -- lua/util/jdtls_workspace.lua for what that does to the type index.
      opts.jdtls_workspace_dir = function(project_name)
        return require("util.jdtls_workspace").claim(project_name).workspace
      end
      opts.jdtls_config_dir = function(project_name)
        return require("util.jdtls_workspace").claim(project_name).config
      end

      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = jdk_runtimes(),
            -- jdtls defaults this to "interactive", which asks permission to
            -- re-sync via a client command nvim never answers — so a changed
            -- build.gradle.kts is silently ignored and new dependencies stay
            -- invisible until a restart.
            updateBuildConfiguration = "automatic",
          },
          maven = { downloadSources = true },
          eclipse = { downloadSources = true },
          -- Buildship always writes .project/.classpath/.settings into the
          -- project root — jdtls 1.60 has no preference to relocate them
          -- (`java.import.generatesMetadataFilesAtProjectRoot` is a vscode-java
          -- extension setting, absent from the server). They are gitignored, so
          -- the fix for cross-tool corruption is to keep a single owner:
          -- lua/util/jdtls_workspace.lua for nvim-vs-nvim, and disabling other
          -- editors' java servers for the rest. OpenCode's jdtls had been
          -- rewriting these prefs to a JDK 21 that contradicts the project's
          -- Gradle toolchain.
          import = {
            gradle = {
              -- `java.gradle.enabled` is not a jdtls setting; the gradle
              -- importer reads `java.import.gradle.*`.
              enabled = true,
              -- Pin the JVM Buildship runs Gradle on, so it cannot be left
              -- pointing at whatever another editor wrote into .settings/.
              java = { home = default_jdk() },
            },
          },
          references = { includeDecompiledSources = true },
          -- "Generate toString()..." in record style — `Membership[id=..., ...]`
          -- to match the record-style accessors from lua/util/java_accessors.lua.
          -- The default template has a space before `[`.
          codeGeneration = {
            toString = {
              template = "${object.className}[${member.name()}=${member.value}, ${otherMembers}]",
              codeStyle = "STRING_CONCATENATION",
            },
          },
          completion = {
            favoriteStaticMembers = {
              "org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*",
              "org.springframework.test.web.servlet.result.MockMvcResultMatchers.*",
              "org.springframework.test.web.servlet.result.MockMvcResultHandlers.*",
              "org.hamcrest.Matchers.*",
              "org.hamcrest.CoreMatchers.*",
              "org.junit.jupiter.api.Assertions.*",
              "org.mockito.Mockito.*",
              "org.mockito.ArgumentMatchers.*",
              "org.assertj.core.api.Assertions.*",
            },
          },
        },
      })

      -- Applied per-attach by the extra's extend_or_override().
      opts.jdtls = function(config)
        local jdk = default_jdk()
        if jdk then
          config.cmd_env = vim.tbl_extend("force", config.cmd_env or {}, {
            JAVA_HOME = jdk,
            PATH = jdk .. "/bin:" .. (vim.env.PATH or ""),
          })
        end
        -- Assign rather than list_extend: the extra builds its `bundles` table
        -- once in config() and shares it across every attach, so extending
        -- would append duplicates for each new project opened this session.
        config.init_options = vim.tbl_extend("force", config.init_options or {}, { bundles = bundles() })
        return config
      end
    end,
  },

  -- K is registered as a jdtls-specific LSP keymap rather than set from
  -- on_attach. LazyVim binds its keymaps through Snacks.keymap.set with an
  -- `lsp` filter, re-applying them on every attach, so a plain
  -- vim.keymap.set() in on_attach loses the race and gets replaced by the
  -- default `vim.lsp.buf.hover()`. Servers are applied in sorted order
  -- (lsp/init.lua:170-177), so "jdtls" lands after the "*" defaults and wins.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        jdtls = {
          keys = {
            { "K", hover, desc = "Hover docs (focusable)", has = "hover" },
            -- Shadows the global <leader>rR (code_runner :RunFile), which for
            -- a project file would launch it with only the JDK on the classpath
            -- and fail on the first reference to a sibling type. Buffer-local,
            -- so it only applies where jdtls is actually attached.
            { "<leader>rR", run_file, desc = "Run file (project classpath)" },
          },
        },
      },
    },
  },
}
