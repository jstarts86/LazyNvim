return {
  {
    "danymat/neogen",
    version = "*",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
      local i = require("neogen.types.template").item

      local function node_text(n)
        return vim.treesitter.get_node_text(n, 0)
      end

      -- Returns "name (Type)" for a formal_parameter node
      local function param_label(param_node)
        local type_str, name_str
        for child in param_node:iter_children() do
          if child:type() == "identifier" then
            name_str = node_text(child)
          elseif child:named() and not type_str then
            type_str = node_text(child)
          end
        end
        if not name_str then return nil end
        return type_str and (name_str .. " (" .. type_str .. ")") or name_str
      end

      -- Extract params (with type), throws, and return presence from a method/constructor node
      local function extract_func(node, body_type)
        local params, throws = {}, {}
        local has_return = false

        for child in node:iter_children() do
          local t = child:type()
          if t == "formal_parameters" then
            for param in child:iter_children() do
              if param:type() == "formal_parameter" then
                local label = param_label(param)
                if label then table.insert(params, label) end
              end
            end
          elseif t == "throws" then
            for tc in child:iter_children() do
              if tc:named() then
                table.insert(throws, node_text(tc))
              end
            end
          elseif t == body_type then
            for stmt in child:iter_children() do
              if stmt:type() == "return_statement" then
                has_return = true
                break
              end
            end
          end
        end

        local result = {}
        if #params > 0 then result[i.Parameter] = params end
        if #throws > 0 then result[i.Throw] = throws end
        if has_return then result[i.Return] = { "" } end
        return result
      end

      require("neogen").setup({
        snippet_engine = "luasnip",
        languages = {
          java = {
            data = {
              func = {
                ["method_declaration"] = {
                  ["0"] = { extract = function(node) return extract_func(node, "block") end },
                },
                ["constructor_declaration"] = {
                  ["0"] = { extract = function(node) return extract_func(node, "constructor_body") end },
                },
              },
              class = {
                -- record Point(int x, int y) → @param x (int), @param y (int)
                ["record_declaration"] = {
                  ["0"] = {
                    extract = function(node)
                      local params = {}
                      for child in node:iter_children() do
                        if child:type() == "formal_parameters" then
                          for param in child:iter_children() do
                            if param:type() == "formal_parameter" then
                              local label = param_label(param)
                              if label then table.insert(params, label) end
                            end
                          end
                        end
                      end
                      return { [i.Parameter] = params }
                    end,
                  },
                },
                -- class fields → @param fieldName (Type)
                ["class_declaration"] = {
                  ["0"] = {
                    extract = function(node)
                      local params = {}
                      for body in node:iter_children() do
                        if body:type() == "class_body" then
                          for field in body:iter_children() do
                            if field:type() == "field_declaration" then
                              local type_str
                              for child in field:iter_children() do
                                if child:type() == "variable_declarator" then
                                  for sub in child:iter_children() do
                                    if sub:type() == "identifier" then
                                      local name = node_text(sub)
                                      local label = type_str and (name .. " (" .. type_str .. ")") or name
                                      table.insert(params, label)
                                    end
                                  end
                                elseif child:named() and child:type() ~= "modifiers" and not type_str then
                                  type_str = node_text(child)
                                end
                              end
                            end
                          end
                        end
                      end
                      return { [i.Parameter] = params }
                    end,
                  },
                },
              },
            },
          },
        },
      })
    end,
    keys = {
      { "<leader>cn", function() require("neogen").generate() end,                   desc = "Generate doc (auto-detect)" },
      { "<leader>cN", function() require("neogen").generate({ type = "class" }) end, desc = "Generate doc (class/record)" },
    },
  },
}
