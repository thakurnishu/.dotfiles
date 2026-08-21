-- Thin wrapper over the herdr CLI. Pure functions, no keymaps, no side effects
-- on load, so this can be poked at from `:lua` while iterating:
--
--   :lua =require("herdr-harness.herdr").find_pane("harness")
--
local M = {}

-- nvim inherits the pane's PATH, but a pane spawned by herdr does not always
-- inherit the interactive login PATH -- the same reason every script in
-- dotfiles/.local/bin prepends it. Resolve once, prefer PATH, fall back to the
-- system profile.
local function herdr_bin()
  if M._bin then
    return M._bin
  end
  if vim.fn.executable("herdr") == 1 then
    M._bin = "herdr"
  else
    local fallback = "/run/current-system/sw/bin/herdr"
    M._bin = vim.fn.executable(fallback) == 1 and fallback or nil
  end
  return M._bin
end

--- Are we inside a herdr pane at all?
function M.available()
  return vim.env.HERDR_ENV == "1" and herdr_bin() ~= nil
end

function M.workspace_id()
  return vim.env.HERDR_WORKSPACE_ID
end

-- A list, not a string: vim.fn.system with a list skips the shell entirely, so
-- payloads with quotes, newlines and $ need no escaping.
local function run(args)
  local bin = herdr_bin()
  if not bin then
    return nil, "herdr not on PATH"
  end
  local out = vim.fn.system(vim.list_extend({ bin }, args))
  if vim.v.shell_error ~= 0 then
    return nil, vim.trim(out)
  end
  return out
end

M.run = run

local function run_json(args)
  local out, err = run(args)
  if not out then
    return nil, err
  end
  local ok, decoded = pcall(vim.json.decode, out)
  if not ok then
    return nil, "herdr returned non-JSON: " .. tostring(out):sub(1, 120)
  end
  if decoded.error then
    return nil, decoded.error.message or "herdr error"
  end
  return decoded.result
end

M.run_json = run_json

--- Every pane in this workspace, joined to its tab label.
--- @return table[] { pane_id, tab_id, tab_label, cwd }
function M.panes()
  local ws = M.workspace_id()
  local result = run_json({ "api", "snapshot" })
  local snap = result and result.snapshot
  if not snap then
    return {}
  end

  local tabs = {}
  for _, t in ipairs(snap.tabs or {}) do
    tabs[t.tab_id] = t
  end

  local out = {}
  for _, p in ipairs(snap.panes or {}) do
    local tab = tabs[p.tab_id]
    if tab and (ws == nil or tab.workspace_id == ws) then
      table.insert(out, {
        pane_id = p.pane_id,
        tab_id = p.tab_id,
        tab_label = tab.label,
        cwd = p.cwd,
      })
    end
  end
  return out
end

--- First pane whose TAB carries this label, in the current workspace.
function M.find_pane(label)
  for _, p in ipairs(M.panes()) do
    if p.tab_label == label then
      return p
    end
  end
  return nil
end

--- Is a recognised agent actually running in this pane?
--- `agent prompt` only works when herdr has detected one; `send-text` always
--- works. This is how we choose between them.
function M.pane_agent(pane_id)
  local result = run_json({ "agent", "list" })
  for _, a in ipairs((result and result.agents) or {}) do
    if a.pane_id == pane_id then
      return a.agent, a.agent_status
    end
  end
  return nil
end

--- What is the pane's foreground process? Used to tell "harness is running"
--- from "the pane is sitting at a shell".
function M.foreground(pane_id)
  local result = run_json({ "pane", "process-info", "--pane", pane_id })
  local procs = result and result.process_info and result.process_info.foreground_processes
  if procs and procs[1] then
    return procs[1].name
  end
  return nil
end

function M.focus_tab(tab_id)
  return run({ "tab", "focus", tab_id })
end

--- opts.env is a plain table; claudecode.nvim needs it to hand the tab its
--- CLAUDE_CODE_SSE_PORT, without which the running agent cannot call back.
function M.create_tab(label, cwd, opts)
  opts = opts or {}
  local args = { "tab", "create", "--label", label, "--no-focus" }
  local ws = M.workspace_id()
  if ws then
    vim.list_extend(args, { "--workspace", ws })
  end
  vim.list_extend(args, { "--cwd", cwd or vim.fn.getcwd() })
  for k, v in pairs(opts.env or {}) do
    vim.list_extend(args, { "--env", k .. "=" .. tostring(v) })
  end
  local result = run_json(args)
  if not result then
    return nil
  end
  return { pane_id = result.root_pane and result.root_pane.pane_id, tab_id = result.tab_id }
end

--- `pane run` types into the pane's shell, so quitting the tool leaves a usable
--- shell rather than closing the tab.
function M.pane_run(pane_id, cmd)
  local args = { "pane", "run", pane_id }
  vim.list_extend(args, cmd)
  return run(args)
end

--- Put text in front of the agent.
--- submit=true uses `agent prompt`, which presses enter for you. That needs a
--- DETECTED agent, so it is attempted only when one is there; otherwise, and by
--- default, the text is typed in and left for you to finish.
function M.send(pane_id, text, opts)
  opts = opts or {}
  if opts.submit and M.pane_agent(pane_id) then
    local out, err = run({ "agent", "prompt", pane_id, text })
    if out then
      return true
    end
    -- fall through to send-text rather than failing: a half-typed prompt you
    -- can still edit beats an error and nothing in the pane.
    vim.notify("herdr-harness: agent prompt failed (" .. tostring(err) .. "), typing instead",
      vim.log.levels.DEBUG)
  end
  local out, err = run({ "pane", "send-text", pane_id, text })
  if not out then
    return false, err
  end
  return true
end

return M
