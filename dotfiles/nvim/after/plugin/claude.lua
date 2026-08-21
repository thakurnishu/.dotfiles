local ok, claudecode = pcall(require, "claudecode")
if not ok then
  return
end

-- Which multiplexer are we inside? Read the env directly rather than shelling
-- out to `printenv`: is_available() is called on redraw, and a system() call
-- per keypress is what made the old version noticeable.
local function in_tmux()
  local v = vim.env.TMUX
  return v ~= nil and v ~= ""
end

local function in_herdr()
  return vim.env.HERDR_ENV == "1"
end

local function get_claude_win_name()
  local cwd_basename = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return cwd_basename .. "-claude"
end

local function win_exists(win_name)
  local count = tonumber(vim.fn.system(
    "tmux list-windows -F '#{window_name}' | grep -c '^" .. win_name .. "$'"
  )) or 0
  return count > 0
end

local tmux_provider = {}

function tmux_provider.setup(term_config)
  tmux_provider.config = term_config or {}
end

function tmux_provider.open(cmd_string, env_table)
  if vim.trim(vim.fn.system("printenv TMUX")) == "" then
    vim.notify("Not inside a tmux session", vim.log.levels.WARN)
    return
  end

  local win_name = get_claude_win_name()
  if win_exists(win_name) then
    vim.fn.system("tmux select-window -t " .. win_name)
    return
  end

  local env_parts = {}
  for k, v in pairs(env_table or {}) do
    table.insert(env_parts, k .. "=" .. vim.fn.shellescape(tostring(v)))
  end
  local full_cmd = table.concat(env_parts, " ") .. " " .. cmd_string
  vim.fn.system("tmux new-window -n " .. win_name .. " " .. vim.fn.shellescape(full_cmd))
end

function tmux_provider.close()
  local win_name = get_claude_win_name()
  if win_exists(win_name) then
    vim.fn.system("tmux kill-window -t " .. win_name)
  end
end

function tmux_provider.simple_toggle(cmd_string, env_table, _effective_config)
  tmux_provider.open(cmd_string, env_table)
end

function tmux_provider.focus_toggle(cmd_string, env_table, _effective_config)
  tmux_provider.open(cmd_string, env_table)
end

function tmux_provider.toggle(cmd_string, env_table, _effective_config)
  tmux_provider.open(cmd_string, env_table)
end

function tmux_provider.get_active_bufnr()
  -- Claude runs in a separate tmux window, not an in-editor buffer.
  return nil
end

function tmux_provider.is_available()
  return in_tmux()
end

-- ---------------------------------------------------------------- herdr ----
-- Claude lives in a TAB of the current workspace rather than a tmux window.
--
-- Tab discovery is DELEGATED to lua/herdr-harness/, which owns it for every
-- harness. Two config files each reimplementing "find the tab, make it, focus
-- it" is what let this morning's claude -> harness rename break one and not the
-- other; there is now one owner.
--
-- Reusing an existing tab does NOT cost you the IDE bridge, though it looks as
-- if it should: the agent in it was started by the picker, so claudecode's env
-- never reached it. Claude Code does not rely on that env -- claudecode.nvim
-- advertises itself in ~/.claude/ide/<port>.lock with its port, authToken and
-- workspaceFolders, and any Claude started in a matching folder can attach with
-- /ide. Env is a convenience for the instance claudecode starts itself.
local hh = require("herdr-harness.herdr")
local herdr_provider = {}

local HARNESS_TAB = "harness"

function herdr_provider.setup(term_config)
  herdr_provider.config = term_config or {}
end

function herdr_provider.open(cmd_string, env_table)
  if not hh.available() then
    vim.notify("Not inside a herdr session", vim.log.levels.WARN)
    return
  end

  local existing = hh.find_pane(HARNESS_TAB)
  if existing then
    hh.focus_tab(existing.tab_id)
    return
  end

  local created = hh.create_tab(HARNESS_TAB, vim.fn.getcwd(), { env = env_table })
  if not created or not created.pane_id then
    vim.notify("herdr: could not create the " .. HARNESS_TAB .. " tab", vim.log.levels.ERROR)
    return
  end
  hh.focus_tab(created.tab_id)
  hh.pane_run(created.pane_id, vim.split(cmd_string, " ", { trimempty = true }))
end

function herdr_provider.close()
  local existing = hh.find_pane(HARNESS_TAB)
  if existing then
    hh.run({ "tab", "close", existing.tab_id })
  end
end

function herdr_provider.simple_toggle(cmd_string, env_table, _cfg)
  herdr_provider.open(cmd_string, env_table)
end

function herdr_provider.focus_toggle(cmd_string, env_table, _cfg)
  herdr_provider.open(cmd_string, env_table)
end

function herdr_provider.toggle(cmd_string, env_table, _cfg)
  herdr_provider.open(cmd_string, env_table)
end

function herdr_provider.get_active_bufnr()
  -- Claude runs in a separate herdr tab, not an in-editor buffer.
  return nil
end

function herdr_provider.is_available()
  return hh.available()
end

-- Only hand claudecode a custom provider when one is actually usable. It warns
-- "Custom table provider configured but provider reports not available" on
-- every redraw otherwise -- which is exactly what happened when this config
-- kept naming the tmux provider while running under herdr. With no provider
-- key, claudecode falls back to its own in-editor terminal.
local terminal_opts = { split_side = "left" }
if in_herdr() then
  terminal_opts.provider = herdr_provider
elseif in_tmux() then
  terminal_opts.provider = tmux_provider
end

claudecode.setup({
  terminal = terminal_opts,
  diff_opts = {
    layout = "unified", -- VS Code-style inline red/green diff instead of a plain split
  },
})

-- Custom inline diff colors. Reapplied on ColorScheme since this file loads
-- before after/plugin/color.lua and colorscheme changes would otherwise wipe them.
local function set_inline_diff_colors()
  vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffAdd", { bg = "#2a4a2a" })
  vim.api.nvim_set_hl(0, "ClaudeCodeInlineDiffDelete", { bg = "#4a2a2a", strikethrough = true })
end

set_inline_diff_colors()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_inline_diff_colors })

local wk_ok, wk = pcall(require, "which-key")
if wk_ok then
  wk.add({ { "<leader>a", group = "AI/Claude Code" } })
end

vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
vim.keymap.set("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
vim.keymap.set("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
vim.keymap.set("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
vim.keymap.set("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
vim.keymap.set("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
vim.keymap.set("x", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
vim.keymap.set("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

local tree_filetypes = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" }
vim.api.nvim_create_autocmd("FileType", {
  pattern = tree_filetypes,
  callback = function(args)
    vim.keymap.set("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", {
      buffer = args.buf,
      desc = "Add file",
    })
  end,
})
