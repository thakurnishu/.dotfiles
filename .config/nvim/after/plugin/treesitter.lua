require'nvim-treesitter.configs'.setup({
  ensure_installed = {
    "c",
    "lua",
    "vim",
    "vimdoc",
    "query",
    "go",
    "python",
    "yaml",
    "json",
    "javascript",
    "terraform",
    -- "html",
    -- "markdown",
    -- "markdown_inline",
  },

  sync_install = false,
  auto_install = false,

  modules = {},  -- Ensure this is included
  ignore_install = {},  -- Add this field to avoid errors


  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
        disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end
  },
})
