-- herdr-harness: push editor context into whichever agent harness this space is
-- running -- claude, codex, opencode, or whatever the picker offers next.
--
-- It works the same for all of them because it does not know which is running:
-- herdr types into the pane, and every harness is a TUI reading a terminal. No
-- protocol, no per-harness adapter, no dependency beyond the herdr CLI.
--
-- One-way by design. The return path (the harness reading the editor, proposing
-- diffs) is phase B -- see docs/nvim-harness-bridge.md.
local herdr = require("herdr-harness.herdr")
local payload = require("herdr-harness.payload")

local M = {}

M.config = {
  tab_label = "harness",   -- the tab herdr-sessionizer creates
  command = { "harness" }, -- what to run when that tab is at a shell
  submit = false,          -- type the payload and leave the cursor there
  focus_on_send = true,    -- land in the harness, where you finish the prompt
}

local function warn(msg)
  vim.notify("herdr-harness: " .. msg, vim.log.levels.WARN)
end

--- Find the harness pane, creating the tab or starting the harness if needed.
--- Three situations, three different right answers -- the third is not
--- hypothetical, since worktree spaces are laid out terminal/lazygit/hunk with
--- no harness tab at all.
function M.pane(opts)
  opts = opts or {}
  if not herdr.available() then
    warn("not inside a herdr pane")
    return nil
  end

  local found = herdr.find_pane(M.config.tab_label)

  if not found then
    if not opts.create then
      return nil
    end
    local created = herdr.create_tab(M.config.tab_label, vim.fn.getcwd())
    if not created or not created.pane_id then
      warn("could not create the " .. M.config.tab_label .. " tab")
      return nil
    end
    herdr.pane_run(created.pane_id, M.config.command)
    return created
  end

  -- Tab is there but sitting at a shell: start the harness in it. Compare
  -- against the shell rather than looking for known agent names, so a harness
  -- we have never heard of still counts as running.
  if opts.create then
    local fg = herdr.foreground(found.pane_id)
    local shells = { zsh = true, bash = true, sh = true, fish = true }
    if fg == nil or shells[fg] then
      herdr.pane_run(found.pane_id, M.config.command)
    end
  end

  return found
end

--- Focus the harness tab, starting one if this space has none.
function M.focus()
  local p = M.pane({ create = true })
  if p and p.tab_id then
    herdr.focus_tab(p.tab_id)
  end
end

--- Send arbitrary text.
function M.send_text(text, opts)
  opts = vim.tbl_extend("force", { submit = M.config.submit }, opts or {})
  local p = M.pane({ create = true })
  if not p then
    return false
  end
  local ok, err = herdr.send(p.pane_id, text, opts)
  if not ok then
    warn("send failed: " .. tostring(err))
    return false
  end
  local want_focus = opts.focus
  if want_focus == nil then
    want_focus = M.config.focus_on_send
  end
  if want_focus then
    herdr.focus_tab(p.tab_id)
  end
  return true
end

--- Visual selection, with its file and line range.
function M.send_selection(opts)
  local sel, err = payload.selection()
  if not sel then
    warn(err)
    return false
  end
  -- Leave visual mode so the editor does not sit highlighted after sending.
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
  return M.send_text(payload.format(sel), opts)
end

--- The current buffer, as an @reference the harness can open itself.
function M.send_buffer(opts)
  local buf, err = payload.buffer()
  if not buf then
    warn(err)
    return false
  end
  return M.send_text(payload.format(buf), opts)
end

--- The file under the cursor in a tree buffer.
function M.send_tree_file(opts)
  local f, err = payload.tree_file()
  if not f then
    warn(err)
    return false
  end
  return M.send_text(payload.format(f), opts)
end

local function keymaps()
  local map = vim.keymap.set
  -- Normal AND visual: you select something, then decide to go and talk about
  -- it. Binding this in normal mode only meant <leader>ac did nothing at all
  -- from a selection, which is exactly when you want it.
  map({ "n", "x" }, "<leader>ac", M.focus, { desc = "Focus harness" })
  map("x", "<leader>as", function() M.send_selection() end, { desc = "Send selection to harness" })
  map("n", "<leader>ab", function() M.send_buffer() end, { desc = "Send buffer ref to harness" })

  -- Same key, different meaning inside a tree: send the file under the cursor.
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
    callback = function(args)
      map("n", "<leader>as", function() M.send_tree_file() end,
        { buffer = args.buf, desc = "Send file to harness" })
    end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts or {})

  -- Bind nothing outside herdr: the keymaps would only ever warn.
  if not herdr.available() then
    return
  end

  keymaps()

  vim.api.nvim_create_user_command("Harness", function(cmd)
    if cmd.args ~= "" then
      M.send_text(cmd.args, { submit = true })
    else
      M.focus()
    end
  end, { nargs = "*", desc = "Focus the harness, or send it a prompt" })
end

return M
