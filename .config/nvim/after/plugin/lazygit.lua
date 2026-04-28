local function get_lazygit_win_name()
  local cwd_basename = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
  return cwd_basename .. "-lazygit"
end

local function tmux_toggle_lazygit()
  if vim.trim(vim.fn.system("printenv TMUX")) == "" then
    vim.cmd("LazyGit")
    return
  end

  local win_name = get_lazygit_win_name()
  local win_exists = tonumber(vim.fn.system(
    "tmux list-windows -F '#{window_name}' | grep -c '^" .. win_name .. "$'"
  )) or 0

  if win_exists > 0 then
    vim.fn.system("tmux select-window -t " .. win_name)
  else
    vim.fn.system("tmux new-window -n " .. win_name .. " 'lazygit'")
  end
end

local function tmux_toggle_lazygit_config()
  if vim.trim(vim.fn.system("printenv TMUX")) == "" then
    vim.cmd("LazyGitConfig")
    return
  end

  local win_name = "lazygit-config"
  local win_exists = tonumber(vim.fn.system(
    "tmux list-windows -F '#{window_name}' | grep -c '^" .. win_name .. "$'"
  )) or 0

  if win_exists > 0 then
    vim.fn.system("tmux select-window -t " .. win_name)
  else
    vim.fn.system("tmux new-window -n " .. win_name .. " 'lazygit git人间'")
  end
end

vim.keymap.set("n", "<leader>gg", tmux_toggle_lazygit, { desc = "Toggle LazyGit in tmux" })
vim.keymap.set("n", "<leader>gc", tmux_toggle_lazygit_config, { desc = "Toggle LazyGitConfig in tmux" })