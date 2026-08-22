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

    -- lualine
    { 'nvim-lualine/lualine.nvim' }, -- Fancier statusline

    -- comments
    { 'numToStr/Comment.nvim' },

    -- noice
    {
      "folke/noice.nvim",
      event = "VeryLazy",
      opts = {},
      dependencies = {
          "MunifTanjim/nui.nvim",
          "rcarriga/nvim-notify",
        }
    },

    -- mini.nvim
    { 'echasnovski/mini.nvim', version = false },

    -- markdown render
    {
      'MeanderingProgrammer/render-markdown.nvim',
      dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons'
      }, -- if you prefer nvim-web-devicons
      ---@module 'render-markdown'
      ---@type render.md.UserConfig
      opts = {
        injections = { enabled = false },
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
      priority = 1001,
      -- Accents overridden to match the palette in
      -- ~/.config/alacritty/themes/themes/catppuccin.toml so nvim and the
      -- terminal agree. Base stays mocha's #1E1E2E.
      opts = {
        flavour = "mocha",
        transparent_background = true,
        color_overrides = {
          mocha = {
            base   = "#262626", -- neutral grey, not mocha's blue-tinted #1E1E2E
            mantle = "#1F1F1F", -- sidebars/floats, one step darker than base
            crust  = "#181818",
            text   = "#D6D6D6",
            red    = "#E86671",
            maroon = "#E86671",
            green  = "#98C379",
            yellow = "#E5C07B",
            peach  = "#E5C07B",
            blue   = "#61AFEF",
            sapphire = "#61AFEF",
            mauve  = "#C678DD",
            pink   = "#C678DD",
            teal   = "#54AFBC",
            sky    = "#54AFBC",
          },
        },
      },
    },

    -- treesitter (main branch rewrite - requires nvim 0.12+)
    {
      'nvim-treesitter/nvim-treesitter',
      branch = 'main',
      lazy = false,
      build = function()
        require('nvim-treesitter').update()
      end,
    },

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

    -- telescope
    {
      "nvim-telescope/telescope.nvim", tag = "0.1.8",
      dependencies = {
        { "nvim-lua/plenary.nvim" },
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      },
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
      "obsidian-nvim/obsidian.nvim",
      version = "*",  -- recommended, use latest release instead of latest commit
      ft = "markdown",
      dependencies = {
        -- Required.
        "nvim-lua/plenary.nvim",
      },
    },

    -- neo-tree
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons", -- optional, but recommended
      },
      lazy = false, -- neo-tree will lazily load itself
    },

    {
      "nickjvandyke/opencode.nvim",
      version = "*",
      lazy = false,  -- Must load on startup so keymaps in after/plugin/opencode.lua are registered
      dependencies = {
        { "folke/snacks.nvim", optional = true },
      },
      -- Off, and unlike claudecode this one was already dead: every path in
      -- after/plugin/opencode.lua goes through tmux, so under herdr  is
      -- nil, no tmux server runs, and its port computes to nil. It was still
      -- holding <C-a>/<C-x> for that dead path -- and had remapped increment
      -- and decrement to +/- to free them. Disabling gives those back.
      --
      -- herdr-harness covers opencode the same as any other harness.
      enabled = false,
    },

--    {
--      "coder/claudecode.nvim",
--      dependencies = { "folke/snacks.nvim" },
--    },

    {
      "coder/claudecode.nvim",
      dependencies = { "folke/snacks.nvim" },
      lazy = false, -- Must load on startup so keymaps in after/plugin/claude.lua are registered
      -- PHASE A: off, so nvim -> harness can be judged on its own.
      --
      -- Disabling here rather than editing after/plugin/claude.lua: that file
      -- opens with  and returns when the plugin
      -- is absent, so this one flag takes its keymaps AND its websocket IDE
      -- server with it. The file stays intact, unedited, for phase B.
      --
      -- While this is false you lose, for Claude only: in-editor diffs
      -- (<leader>aa / <leader>ad), model select, --resume / --continue.
      -- <leader>a* is then uniformly herdr-harness, every key working for
      -- every harness -- which is the property being tested.
      --
      -- Phase B: flip to true, then decide (docs/nvim-harness-bridge.md B5).
      enabled = false,
    },

    {
      "kdheepak/lazygit.nvim",
      dependencies = {
          "nvim-lua/plenary.nvim",
      },
    },

    -- git blame
    {
      "f-person/git-blame.nvim",
      event = "VeryLazy",
      opts = {
        enabled = true, -- toggle with <leader>gb
        message_template = "  <author> • <date> • <summary>",
        date_format = "%r",
        message_when_not_committed = "  Not committed yet",
        highlight_group = "Comment",
        max_commit_summary_length = 60,
        delay = 300,
      },
    },

    -- copilot
    {
      "github/copilot.vim",
    },

    -- helm-template
    {
      "towolf/vim-helm"
    },
  },
})
