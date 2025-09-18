return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      -- "IllustratedMan-code/telescope-conda.nvim",
    },
    -- config = function()
    --   require('telescope').setup {
    --     extensions = {
    --       conda = {
    --         anaconda_path = "/opt/anaconda3"
    --       }
    --     }
    --   }
    -- end,
    keys = {
      -- { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files (cwd)" },
      -- {
      --   "<leader>fa",
      --   desc = "choose the anaconda environment",
      --   function()
      --     require("telescope").extensions.conda.conda({})
      --   end,
      -- },
      {
        "<leader>fd",
        desc = "flutter commands",
        function()
          require("telescope").extensions.flutter.commands()
        end,
      },
    },
    opts = {
      defaults = {
        mappings = {
          i = {
            ["<C-f>"] = "move_selection_next", -- go to next item
            ["<C-b>"] = "move_selection_previous", -- go to previous item
          },
        },
      },
    },
  },
}
