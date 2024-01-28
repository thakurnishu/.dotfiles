local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
vim.api.nvim_set_hl(0,"Normal", { bg = "none" })
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    {
        'nvim-telescope/telescope.nvim', tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
        'nvim-telescope/telescope-ui-select.nvim',
    },
    {
        'ellisonleao/gruvbox.nvim',
        priority = 1000 , config = true, opts = ...
    },
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate'
    },
    {	-- harpoon to add file to buffer
        'ThePrimeagen/harpoon',
    },
    {	-- undo tree
        'mbbill/undotree',
    },
    {	-- vim plugin for git
        'tpope/vim-fugitive',
    },
    {	-- LSP Config
        'VonHeikemen/lsp-zero.nvim', branch = 'v3.x',
        'neovim/nvim-lspconfig',
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/nvim-cmp',
        'L3MON4D3/LuaSnip',
    },
    {
        'williamboman/mason.nvim',
        config = function()
            require("mason").setup()
        end
    },
    {
        'williamboman/mason-lspconfig.nvim',
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = {
                    "ansiblels",
                    "azure_pipelines_ls",
                    "bashls",
                    "clangd",
                    "dockerls",
                    "dotls",
                    "gopls",
                    "groovyls",
                    "helm_ls",
                    "jsonls",
                    "lua_ls",
                    "marksman",
                    "sqls",
                    "terraformls",
                    "yamlls",
                }
            })
        end
    },
}, {})
