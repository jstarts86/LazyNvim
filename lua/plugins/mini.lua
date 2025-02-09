return {
  {
    "echasnovski/mini.move",
    opts = {
      mapping = {
        right = '<S-l>',
        down = '<S-j>',
        up = '<S-k>',
        left = '<S-h>',
      },
      -- Options which control moving behavior
      options = {
        -- Automatically reindent selection during linewise vertical move
        reindent_linewise = true,
      },
    },
  },
}
