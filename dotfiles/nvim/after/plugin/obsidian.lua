-- obsidian.nvim discards any workspace whose directory is missing, and then
-- errors "At least one workspace is required!" if none are left. On a machine
-- where the notes repo isn't cloned that fires on every startup, so only call
-- setup() when the workspace actually exists.
local workspace = vim.fn.expand("~/src/github.com/personal/second_brain")

if vim.fn.isdirectory(workspace) == 0 then
  return
end

require("obsidian").setup({
  ui = { enable = false },
  workspaces = {
    {
      name = "Notes",
      path = workspace,
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
