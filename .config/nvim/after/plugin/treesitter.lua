require'nvim-treesitter.configs'.setup({
  ensure_installed = {
    "c",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "go",
    "yaml",
    "json",
    "html",
    "javascript",
    "markdown",
    "markdown_inline",
  },

  sync_install = false,
  auto_install = false,

  modules = {},  -- Ensure this is included
  ignore_install = {},  -- Add this field to avoid errors


  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
})
