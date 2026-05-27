return {
  {
    "mfussenegger/nvim-jdtls",
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

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        group = vim.api.nvim_create_augroup("jdtls_setup", { clear = true }),
        callback = function()
          jdtls.start_or_attach(make_config())
        end,
      })
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
}
