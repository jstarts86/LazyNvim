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
}
