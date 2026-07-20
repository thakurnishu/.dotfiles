vim.keymap.set("n", "<leader>gb", "<cmd>GitBlameToggle<cr>", { desc = "Toggle [G]it [B]lame virtual text" })
vim.keymap.set("n", "<leader>go", "<cmd>GitBlameOpenCommitURL<cr>", { desc = "[G]it blame [O]pen commit URL" })
vim.keymap.set("n", "<leader>gs", "<cmd>GitBlameCopySHA<cr>", { desc = "[G]it blame copy [S]HA" })
vim.keymap.set("n", "<leader>gu", "<cmd>GitBlameCopyCommitURL<cr>", { desc = "[G]it blame copy commit [U]RL" })
