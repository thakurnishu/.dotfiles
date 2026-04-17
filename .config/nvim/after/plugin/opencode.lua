local ok, opencode = pcall(require, "opencode")
if not ok then
  return
end

local function get_opencode_win_name()
  local cwd_basename = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return cwd_basename .. "-opencode"
end

local function get_opencode_port()
  local session_id = tonumber(vim.fn.system("tmux display-message -p '#{session_id}' | tr -d '$\\n'")) or 0
  return 30000 + (session_id % 10000)
end

local function tmux_toggle_opencode()
  if vim.trim(vim.fn.system("printenv TMUX")) == "" then
    vim.notify("Not inside a tmux session", vim.log.levels.WARN)
    return
  end

  local win_name = get_opencode_win_name()
  local win_exists = tonumber(vim.fn.system(
    "tmux list-windows -F '#{window_name}' | grep -c '^" .. win_name .. "$'"
  )) or 0

  if win_exists > 0 then
    vim.fn.system("tmux select-window -t " .. win_name)
  else
    local port = get_opencode_port()
    vim.fn.system("tmux new-window -n " .. win_name .. " 'opencode --port " .. port .. "'")
  end
end

local function get_server_port()
  if vim.trim(vim.fn.system("printenv TMUX")) == "" then
    return nil
  end
  return get_opencode_port()
end

vim.g.opencode_opts = {
  server = {
    port = get_server_port(),
    start = tmux_toggle_opencode,
    toggle = tmux_toggle_opencode,
  },
}

vim.o.autoread = true -- Required for opts.events.reload

-- Remap increment/decrement since <C-a>/<C-x> are taken by opencode
vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })

-- Keymaps
vim.keymap.set("n", "<C-a>", function() opencode.ask(nil, { submit = true }) end, { desc = "Ask opencode" })
vim.keymap.set("x", "<C-a>", function() opencode.ask("@this: ", { submit = true }) end, { desc = "Ask opencode about selection" })
vim.keymap.set({ "n", "x" }, "<C-x>", function() opencode.select() end, { desc = "Execute opencode action" })
vim.keymap.set({ "n", "t" }, "<leader>oo", tmux_toggle_opencode, { desc = "Toggle opencode (tmux window)" })
vim.keymap.set({ "n", "t" }, "<M-.>", tmux_toggle_opencode, { desc = "Toggle opencode (tmux window)" })
vim.keymap.set({ "n", "x" }, "go", function() return opencode.operator("@this ") end, { expr = true, desc = "Add range to opencode" })
vim.keymap.set("n", "goo", function() return opencode.operator("@this ") .. "_" end, { expr = true, desc = "Add line to opencode" })
vim.keymap.set("n", "<S-C-u>", function() opencode.command("session.half.page.up") end, { desc = "Scroll opencode up" })
vim.keymap.set("n", "<S-C-d>", function() opencode.command("session.half.page.down") end, { desc = "Scroll opencode down" })
