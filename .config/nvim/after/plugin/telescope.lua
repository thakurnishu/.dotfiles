local builtin = require("telescope.builtin")
local keymap = vim.keymap.set

-- Keybindings for telescope
keymap("n", "<leader>ff", builtin.find_files, {})
keymap("n", "<leader>ps", builtin.grep_string, {})
-- Telescope setup with UI select extension
require("telescope").setup({
  extensions = {
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({})
    }
  }
})

-- Load the ui-select extension
require("telescope").load_extension("ui-select")
