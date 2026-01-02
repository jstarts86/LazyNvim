-- Hide jdt://... URLs inside markdown links in hover docs
vim.cmd([[
  syntax match mkJdtLink /jdt:\/\/.*/ containedin=markdownLink conceal
]])

