return {
  {
    -- Active again: jls (idelice/nvim-jls, block below) had too many errors,
    -- so we flipped back. The jls config is kept intact behind enabled=false.
    "mfussenegger/nvim-jdtls",
    enabled = true,
    ft = { "java" },
    -- Full ownership: bypass LazyVim's opts hook and set up directly
    config = function()
      local jdtls = require("jdtls")

      local function make_config()
        -- vim.fs.root (nvim 0.10+): walks up from buf 0 to find project root
        local root_dir = vim.fs.root(0, {
          "gradlew", "mvnw", "pom.xml",
          "build.gradle", "build.gradle.kts",
          "settings.gradle", "settings.gradle.kts",
          ".git",
        })

        local project_name = root_dir and vim.fn.fnamemodify(root_dir, ":t") or "unknown"
        -- vim.fn.stdpath("cache"): ~/.cache/nvim on macOS
        local workspace = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

        local lombok = vim.fn.expand("~/.local/share/nvim/mason/packages/jdtls/lombok.jar")

        return {
          cmd = {
            "jdtls",
            "-data", workspace,
            "--jvm-arg=-javaagent:" .. lombok,
          },
          root_dir = root_dir,
          capabilities = require("blink.cmp").get_lsp_capabilities(),

          settings = {
            java = {
              maven = {
                downloadSources = true,
              },
              eclipse = {
                downloadSources = true,
              },
              gradle = {
                enabled = true,
              },
              references = {
                includeDecompiledSources = true,
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
          },

          init_options = {
            bundles = {},
          },

          handlers = {
            ["$/progress"] = function() end,
          },

          on_attach = function(_, bufnr)
            local map = function(mode, lhs, rhs, desc)
              vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Java: " .. desc })
            end

            -- Hover with navigable float: focus with <C-w>w, then gd on any symbol
            map("n", "K", function()
              local src_bufnr = vim.api.nvim_get_current_buf()
              local src_win = vim.api.nvim_get_current_win()
              local src_cursor = vim.api.nvim_win_get_cursor(src_win)
              local params = vim.lsp.util.make_position_params()

              vim.lsp.buf_request(src_bufnr, "textDocument/hover", params, function(err, result)
                if err or not result or not result.contents then return end
                local lines = vim.lsp.util.convert_input_to_markdown_lines(result.contents)
                lines = vim.lsp.util.trim_empty_lines(lines)
                if vim.tbl_isempty(lines) then return end

                for i, line in ipairs(lines) do
                  if line:find("jdt://", 1, true) then
                    line = (line:gsub("%[([^%]]+)%]%(jdt://[^%)]*%)", "%1"))
                  end
                  if line:sub(1, 1) == "|" then
                    local cells = vim.split(line, "|", { plain = true })
                    for j, cell in ipairs(cells) do
                      local trimmed = vim.trim(cell)
                      cells[j] = (trimmed == "" or trimmed:match("^[%-:]+$"))
                        and cell
                        or (" " .. trimmed .. " ")
                    end
                    line = table.concat(cells, "|")
                  end
                  lines[i] = line
                end

                local float_bufnr, float_win = vim.lsp.util.open_floating_preview(
                  lines, "markdown", { focusable = true, focus = false, border = "rounded" }
                )

                -- gd on any word in the float does a workspace symbol lookup
                vim.keymap.set("n", "gd", function()
                  local word = vim.fn.expand("<cword>")
                  if vim.api.nvim_win_is_valid(float_win) then
                    vim.api.nvim_win_close(float_win, true)
                  end
                  vim.api.nvim_set_current_win(src_win)
                  vim.api.nvim_win_set_cursor(src_win, src_cursor)
                  local ok = pcall(require("telescope.builtin").lsp_workspace_symbols, { query = word })
                  if not ok then
                    vim.lsp.buf.workspace_symbol(word)
                  end
                end, { buffer = float_bufnr, nowait = true, desc = "Java: Go to definition" })

                vim.keymap.set("n", "q", function()
                  if vim.api.nvim_win_is_valid(float_win) then
                    vim.api.nvim_win_close(float_win, true)
                  end
                end, { buffer = float_bufnr, nowait = true })
              end)
            end, "Hover docs")

            -- jdtls extras: not available via plain vim.lsp.buf
            map("n", "<leader>co", jdtls.organize_imports, "Organize Imports")
            map("n", "<leader>cv", jdtls.extract_variable, "Extract Variable")
            map("n", "<leader>cc", jdtls.extract_constant, "Extract Constant")
            map("v", "<leader>cv", function() jdtls.extract_variable({ visual = true }) end, "Extract Variable")
            map("v", "<leader>cm", function() jdtls.extract_method({ visual = true }) end, "Extract Method")
            map("n", "<leader>ct", jdtls.test_nearest_method, "Test Nearest Method")
            map("n", "<leader>cT", jdtls.test_class, "Test Class")
          end,
        }
      end

      local function start()
        if vim.bo.filetype == "java" then
          jdtls.start_or_attach(make_config())
        end
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        group = vim.api.nvim_create_augroup("jdtls_setup", { clear = true }),
        callback = start,
      })

      start()
    end,
  },
  {
    "cskeeters/javadoc.nvim",
    enabled = false,
    ft = "java",
    init = function()
      vim.g.javadoc_path = vim.fn.expand("~/Coding/java-docs/api")
    end,
    keys = {
      { "<leader>cj", "<Plug>JavadocOpen", ft = "java", desc = "Java: Open Javadoc for word under cursor" },
    },
  },
  -- LuaSnip from_lua loader: enables custom Lua snippets from ~/.config/nvim/luasnippets/
  {
    "L3MON4D3/LuaSnip",
    opts = function(_, opts)
      require("luasnip.loaders.from_lua").lazy_load()
      return opts
    end,
  },
  -- JLS (idelice/jls) — disabled: too many errors in practice, switched back
  -- to jdtls (block above). Config kept intact so flipping `enabled` back to
  -- true restores jls instantly. The server binary is installed via mason
  -- (`:MasonInstall jls`); nvim-jls auto-detects the mason package path.
  -- Do NOT call lspconfig.jls.setup() — the plugin does that internally.
  -- It starts automatically on FileType=java via its own ftplugin.
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "jls" } },
  },
  {
    "idelice/nvim-jls",
    main = "jls",
    enabled = false,
    ft = { "java" },
    opts = {
      -- jls_dir defaults to the mason package when installed, else the managed
      -- ~/.local/share/nvim/jls install (:JlsInstall).
      auto_restart = true,
      inlay_hints = { enabled = true },
      settings = {},
    },
    config = function(_, opts)
      -- Hover-docs workaround. jls has no Gradle source resolution
      -- (InferConfig.buildDocPath() returns empty for Gradle), so javadoc for
      -- third-party libs never loads. But jls already resolves the binary
      -- classpath and caches it as gradle-module-graph.json. We read that, find
      -- each dependency's sibling -sources.jar in the Gradle cache, and feed
      -- both back via the `classPath`/`docPath` settings (under the `java` key,
      -- which is how jls unwraps didChangeConfiguration). Setting classPath also
      -- flips jls into "explicit" mode — the only mode where it reads docPath.
      local cache_root = (vim.env.XDG_CACHE_HOME or vim.fn.expand("~/.cache")) .. "/jls"
      local memo = {}

      local function gradle_paths(root_dir)
        if not root_dir or root_dir == "" then return nil end
        if memo[root_dir] then return memo[root_dir] end

        local base = vim.fn.fnamemodify(root_dir, ":t")
        local graphs = vim.fn.glob(cache_root .. "/" .. base .. "-*/gradle-module-graph.json", false, true)
        if #graphs == 0 then return nil end -- jls hasn't resolved yet; restart picks it up
        table.sort(graphs, function(a, b) return vim.fn.getftime(a) > vim.fn.getftime(b) end)

        local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(graphs[1]), "\n"))
        if not ok or type(data) ~= "table" or not data.modules then return nil end

        local class_path, doc_path, seen = {}, {}, {}
        for _, mod in ipairs(data.modules) do
          for _, jar in ipairs(mod.externalClasspath or {}) do
            if not seen[jar] and jar:sub(-4) == ".jar" then
              seen[jar] = true
              table.insert(class_path, jar)
              local stem = vim.fn.fnamemodify(jar, ":t:r") -- artifact-version
              local versdir = vim.fn.fnamemodify(jar, ":h:h") -- .../<version>/
              local srcs = vim.fn.glob(versdir .. "/*/" .. stem .. "-sources.jar", false, true)
              if srcs[1] then table.insert(doc_path, srcs[1]) end
            end
          end
          local out_dir = mod.projectDir .. "/build/classes/java/main"
          if vim.fn.isdirectory(out_dir) == 1 then
            table.insert(class_path, out_dir)
          end
        end
        if #class_path == 0 then return nil end

        local result = { classPath = class_path, docPath = doc_path }
        memo[root_dir] = result
        return result
      end

      -- The start/restart path calls require("jls.lsp").make_lsp_config(state, opts),
      -- not the jls module wrapper, so patch the lsp module directly.
      local lsp = require("jls.lsp")
      local orig_make = lsp.make_lsp_config
      lsp.make_lsp_config = function(state, start_opts)
        local cfg, err = orig_make(state, start_opts)
        if not cfg then return cfg, err end
        local root_dir = cfg.root_dir
        if type(root_dir) == "function" then
          root_dir = root_dir(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
        end
        local paths = gradle_paths(root_dir)
        if paths then
          cfg.settings = vim.tbl_deep_extend("force", cfg.settings or {}, {
            java = { classPath = paths.classPath, docPath = paths.docPath },
          })
        end
        return cfg, err
      end

      -- After changing dependencies: :JlsClearCache, then this to re-read sources.
      vim.api.nvim_create_user_command("JlsRefreshDocs", function()
        memo = {}
        require("jls").restart()
      end, { desc = "JLS: re-resolve source jars for hover docs and restart" })

      require("jls").setup(opts)

      -- Auto-refresh: after JLS attaches, poll for gradle-module-graph.json.
      -- Once it appears (after initial compilation), restart with classPath/docPath
      -- so hover/Javadoc works for third-party libraries.
      -- Only fires once per root_dir to prevent infinite restart loops.
      local auto_refreshed_roots = {}
      local auto_refresh_group = vim.api.nvim_create_augroup("JlsAutoRefreshDocs", { clear = true })

      -- Disable automatic signature help popup: JLS re-sends too aggressively,
      -- causing flicker. Manual trigger is still available via <C-\>.
      -- Clearing triggerCharacters prevents the LSP client from auto-requesting;
      -- the handler no-op is belt-and-suspenders in case any still sneak through.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = auto_refresh_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "jls" then return end
          local sig = client.server_capabilities.signatureHelpProvider
          if sig then
            sig.triggerCharacters = nil
            sig.signatureRetriggerCharacters = nil
          end
          if not client.handlers["textDocument/signatureHelp"] then
            client.handlers["textDocument/signatureHelp"] = function() end
          end
        end,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = auto_refresh_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "jls" then return end

          local root_dir = client.config.root_dir
          if type(root_dir) == "function" then
            root_dir = root_dir(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
          end
          if not root_dir or root_dir == "" or auto_refreshed_roots[root_dir] then return end

          -- Poll for the gradle graph file, up to 30 seconds (60 * 500ms)
          local attempts, max_attempts = 0, 60
          local timer = vim.uv.new_timer()
          timer:start(500, 500, vim.schedule_wrap(function()
            if not vim.lsp.get_client_by_id(client.id) then
              timer:stop()
              if not timer:is_closing() then timer:close() end
              return
            end
            attempts = attempts + 1
            local paths = gradle_paths(root_dir)
            if paths then
              timer:stop()
              if not timer:is_closing() then timer:close() end
              auto_refreshed_roots[root_dir] = true
              memo[root_dir] = nil
              require("jls").restart()
            elseif attempts >= max_attempts then
              timer:stop()
              if not timer:is_closing() then timer:close() end
            end
          end))
        end,
      })

      -- Make hover docs survive JLS's go-to-definition "poison".
      --
      -- Root cause (confirmed from the LSP log + jls.jar bytecode): hovering a
      -- third-party class pulls Javadoc from the -sources.jar fed via `docPath`.
      -- But `gd` issues textDocument/definition, and JLS answers it by
      -- DECOMPILING the class server-side (org.javacs DefinitionProvider ->
      -- ExternalBinaryDecompiler). Decompiling swaps that type's backing source
      -- to the Javadoc-less decompiled file, so every later hover on it returns
      -- only the bare signature. It happens entirely inside the server -- there
      -- is no `sourcePath` setting to point navigation at the source jar
      -- (JavaLanguageServer reads only classPath/docPath), and a restart doesn't
      -- reliably recover it -- so we can't stop it client-side without
      -- reimplementing navigation.
      --
      -- So instead: cache good hover results and replay them. HoverProvider
      -- always renders the same ```java signature block (its fully-qualified
      -- name comes from getQualifiedName(), unaffected by decompilation); only
      -- the doc body after it vanishes once poisoned. We key by that signature
      -- -- class-like elements by their qualified type name (whitespace-robust,
      -- collision-free), members by their full normalized signature -- and when
      -- a hover returns body-less but we hold a cached doc for that key, we swap
      -- it back in before it renders.
      --
      -- nvim 0.12's vim.lsp.buf.hover() assembles results in its own
      -- buf_request_all callback and never consults
      -- client.handlers["textDocument/hover"] (which is why a handler-override
      -- cache never fired), so we hook one level lower: wrap client.request for
      -- the hover method.
      local hover_cache = {}

      local function hover_text(result)
        local c = result and result.contents
        if not c then return nil end
        if type(c) == "string" then return c end
        if c.value then return c.value end -- MarkupContent
        local parts = {}
        for _, item in ipairs(c) do
          if type(item) == "string" then
            parts[#parts + 1] = item
          elseif type(item) == "table" and item.value then
            parts[#parts + 1] = item.value
          end
        end
        return #parts > 0 and table.concat(parts, "\n") or nil
      end

      -- The first fenced ```java block: the element's signature.
      local function signature_block(text)
        return text:match("```java%s*\n(.-)\n```") or text:match("```%s*\n(.-)\n```")
      end

      -- A stable key for the symbol, identical before and after the poison.
      local function hover_key(sig)
        local fqn = sig:match("%f[%w]class%s+([%w_%.]+)")
          or sig:match("%f[%w]interface%s+([%w_%.]+)")
          or sig:match("%f[%w]enum%s+([%w_%.]+)")
          or sig:match("%f[%w]record%s+([%w_%.]+)")
        if fqn and fqn:find(".", 1, true) then
          return "type:" .. fqn
        end
        local norm = vim.trim(sig):gsub("%s+", " ")
        return "sig:" .. norm
      end

      -- Javadoc present? HoverProvider lays results out as [modifiers] [```java
      -- signature```] [--- doc body]; the poison strips only the doc body. So
      -- remove everything through the first code block and check whether any
      -- prose remains -- format-agnostic, and never mistakes the signature or
      -- modifier text for docs (which would let a poisoned hover overwrite a
      -- cached good one).
      local function has_docs(text)
        local after = text:gsub(".-```java.-\n```", "", 1)
        if after == text then
          after = text:gsub(".-```.-\n```", "", 1) -- generic fence fallback
        end
        if after == text then return false end -- no signature block found
        return after:gsub("[%s%-]", ""):match("%w") ~= nil
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = auto_refresh_group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client or client.name ~= "jls" then return end
          if client._jls_hover_cache_patched then return end
          client._jls_hover_cache_patched = true

          local orig_request = client.request
          client.request = function(self, method, params, handler, bufnr)
            if method == "textDocument/hover" and type(handler) == "function" then
              local user_handler = handler
              handler = function(err, result, ctx, hcfg)
                if not err and result and result.contents then
                  local text = hover_text(result)
                  local sig = text and signature_block(text)
                  if sig then
                    local key = hover_key(sig)
                    if has_docs(text) then
                      hover_cache[key] = vim.deepcopy(result)
                    elseif hover_cache[key] then
                      local cached = vim.deepcopy(hover_cache[key])
                      cached.range = result.range -- highlight the symbol at the current position
                      result = cached
                    end
                  end
                end
                return user_handler(err, result, ctx, hcfg)
              end
            end
            return orig_request(self, method, params, handler, bufnr)
          end
        end,
      })
    end,
  },
}
