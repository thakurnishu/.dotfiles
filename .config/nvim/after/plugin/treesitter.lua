-- nvim-treesitter main branch (rewrite for nvim 0.12+)
-- configs.setup() no longer exists; use the new API
local ok, nts = pcall(require, 'nvim-treesitter')
if not ok then return end

nts.setup({
  install_dir = vim.fn.stdpath('data') .. '/site',
})

-- Install parsers
nts.install({
  'c', 'lua', 'vim', 'vimdoc', 'query',
  'go', 'bash', 'regex', 'python',
  'yaml', 'json', 'javascript',
  'terraform', 'markdown', 'markdown_inline',
})

-- Enable treesitter highlighting per filetype
vim.api.nvim_create_autocmd('FileType', {
  pattern = {
    'c', 'lua', 'vim', 'vimdoc', 'query',
    'go', 'sh', 'python',
    'yaml', 'json', 'javascript',
    'terraform', 'markdown',
  },
  callback = function(ev)
    local max_filesize = 100 * 1024 -- 100 KB
    local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(ev.buf))
    if ok and stats and stats.size > max_filesize then
      return
    end
    pcall(vim.treesitter.start, ev.buf, ev.match)
  end,
})
