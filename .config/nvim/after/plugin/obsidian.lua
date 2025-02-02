require("obsidian").setup({
  ui = { enable = false },
  workspaces = {
    {
      name = "Notes",
      path = "~/Desktop/src/obsidian/mahakal_vault",
    },
  },
  notes_subdir = "MainNotes",
  disable_frontmatter = true,
  templates = {
    folder = "Templates",
    date_format = "%d-%m-%Y",
    time_format = "%H:%M",
  },
})

-- Populate Templates
vim.keymap.set('n', "<leader>pt", ":ObsidianTemplate<CR>")
