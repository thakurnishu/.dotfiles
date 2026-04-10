require("obsidian").setup({
  ui = { enable = false },
  workspaces = {
    {
      name = "Notes",
      path = "~/Desktop/src/github.com/personal/second_brain",
    },
  },
  notes_subdir = "MainNotes",
  legacy_commands = false,
  templates = {
    folder = "Templates",
    date_format = "%d-%m-%Y",
    time_format = "%H:%M",
  },
  frontmatter = {
    enabled = false
  },
})

-- Populate Templates
vim.keymap.set('n', "<leader>pt", ":ObsidianTemplate<CR>")
