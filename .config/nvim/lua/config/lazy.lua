-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- lualine
    { 'nvim-lualine/lualine.nvim' }, -- Fancier statusline

    -- comments
    { 'numToStr/Comment.nvim' },

    -- noice
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      opts = {},
    },

    -- mini.nvim
    { 'echasnovski/mini.nvim', version = false },

    -- markdown render
    {
      'MeanderingProgrammer/markdown.nvim',
      main = "render-markdown",
      opts = {},
      name = 'render-markdown',
      dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
      },
    },

    -- colors
    {
      'ellisonleao/gruvbox.nvim',
      lazy = false,
      priority = 1000,
    },
    {
      "catppuccin/nvim",
      name = "catppuccin",
      lazy = false,
      priority = 1001
    },

    -- treesitter
    { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },

    -- toggleterm
    { 'akinsho/toggleterm.nvim' },

    -- completion
    {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/nvim-cmp',
    },

    -- harpoon
    {
      "ThePrimeagen/harpoon",
      branch = "harpoon2",
      dependencies = { "nvim-lua/plenary.nvim" },
    },

    -- lsp
    {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
    },
    {
      "folke/lazydev.nvim",
      ft = "lua", -- only load on lua files
      opts = {
        library = {
          { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        },
      },
    },

    -- telescope
    {
      "nvim-telescope/telescope.nvim", tag = "0.1.8",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },

    -- no neck pain
    {
      "shortcuts/no-neck-pain.nvim",
      cmd = "NoNeckPain",
      keys = { { "<leader>nn", "<cmd>NoNeckPain<cr>", desc = "[N]o [N]eckpain" } },
      opts = {},
    },

    -- dap ui
    {
      "rcarriga/nvim-dap-ui",
      dependencies = {
        "mfussenegger/nvim-dap",
        "nvim-neotest/nvim-nio"
      }
    },

    -- obsidian
    {
      "epwalsh/obsidian.nvim",
      version = "*",  -- recommended, use latest release instead of latest commit
      lazy = true,
      ft = "markdown",
      dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
      },
    },
  },
})
