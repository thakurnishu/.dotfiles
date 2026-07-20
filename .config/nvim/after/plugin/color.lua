-- vim.cmd([[colorscheme gruvbox]])
vim.cmd([[colorscheme catppuccin]])
vim.o.background = "dark" -- or "light" for light mode

-- Neo-tree git status colors (catppuccin mocha palette).
-- Blue is avoided here — it is already the plain file/directory color.
local neotree_git_colors = {
  NeoTreeGitUntracked = { fg = "#f5c2e7", italic = false }, -- pink   — untracked, never added to git
  NeoTreeGitAdded     = { fg = "#a6e3a1" },                 -- green  — staged add
  NeoTreeGitStaged    = { fg = "#94e2d5" },                 -- teal   — staged change
  NeoTreeGitModified  = { fg = "#f9e2af" },                 -- yellow — modified
  NeoTreeGitRenamed   = { fg = "#cba6f7" },                 -- mauve  — renamed
  NeoTreeGitDeleted   = { fg = "#f38ba8" },                 -- red    — deleted
  NeoTreeGitConflict  = { fg = "#eba0ac", bold = true },    -- maroon — conflict
  NeoTreeGitIgnored   = { fg = "#6c7086" },                 -- grey   — gitignored
}

local function apply_neotree_git_colors()
  for group, opts in pairs(neotree_git_colors) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

apply_neotree_git_colors()

-- Reapply after any colorscheme change, which resets highlight groups
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("NeoTreeGitColors", { clear = true }),
  callback = apply_neotree_git_colors,
})
