vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Vim
vim.keymap.set("n", "<c-e>", ":!")

-- Git
vim.keymap.set('n', "<leader>G", ":Git ")

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

-- buffers
vim.keymap.set("n", "tk", ":blast<CR>", {silent = true, noremap = true})
vim.keymap.set("n", "tj", ":bfirst<CR>", {silent = true, noremap = true})
vim.keymap.set("n", "th", ":bprev<CR>", {silent = true, noremap = true})
vim.keymap.set("n", "tl", ":bnext<CR>", {silent = true, noremap = true})
vim.keymap.set("n", "td", ":bdelete<CR>", {silent = true, noremap = true})
