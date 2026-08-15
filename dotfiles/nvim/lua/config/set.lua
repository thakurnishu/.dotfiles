-- Tab indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Use real tabs in Makefiles
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.softtabstop = 4
  end,
})


-- disable vim backup but allow untree to get backup file
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- better search
vim.opt.hlsearch = false
vim.opt.incsearch = true


vim.opt.scrolloff = 12
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50

-- obsidian recommended
vim.opt_local.conceallevel = 2

vim.opt.colorcolumn="130"

-- Code folding (VS Code-style: show first + last line of fold)
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldtext = "substitute(getline(v:foldstart), \"^\\\\s*\", \"\", \"\") . \" ... \" . substitute(getline(v:foldend), \"^\\\\s*\", \"\", \"\")"
