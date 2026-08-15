local builtin = require("telescope.builtin")
local keymap = vim.keymap.set

-- Keybindings for telescope
keymap("n", "<C-f>", builtin.find_files, {})
keymap("n", "<leader>ps", builtin.grep_string, {})
keymap("n", "<leader>lg", builtin.live_grep, {})
keymap("n", "<leader>nc", function ()
  builtin.find_files {
    cwd = vim.fn.stdpath("config")
  }
end)

-- Telescope setup with UI select extension
require("telescope").setup({
  defaults = {
    preview = {
      treesitter = false,
    },
  },
  extensions = {
    fzf = {}
  },
  pickers = {
    find_files = {
      theme = "ivy"
    }
  },
})

-- Load the extension
require("telescope").load_extension("fzf")
