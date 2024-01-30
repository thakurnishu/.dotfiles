local mark = require('harpoon.mark')
local ui = require('harpoon.ui')


vim.keymap.set("n", "<leader>a", mark.add_file)

vim.keymap.set("n", "<C-p>", ui.toggle_quick_menu)
vim.keymap.set("n", "<M-q>", function() ui.nav_file(1) end)
vim.keymap.set("n", "<M-w>", function() ui.nav_file(2) end)
vim.keymap.set("n", "<M-[>", function() ui.nav_file(3) end)
vim.keymap.set("n", "<M-]>", function() ui.nav_file(4) end)
vim.keymap.set("n", "<M-;>", function() ui.nav_file(5) end)
vim.keymap.set("n", "<M-'", function() ui.nav_file(6) end)
