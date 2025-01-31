vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Copy to Clipboard
vim.keymap.set({"n", "v"}, "<leader>y", [["+y]])

-- Change Every Matched Word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make Current file Executable
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- Source Lua vim config
vim.keymap.set("n", "<leader><leader>", function()
  vim.cmd("so")
end)

