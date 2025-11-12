-- neo-tree configuration
require("neo-tree").setup({
  close_if_last_window = true,
  popup_border_style = "rounded",
  enable_git_status = true,
  enable_diagnostics = true,
  clipboard = {
    sync = "global", -- or "global"/"universal" to share a clipboard for each/all Neovim instance(s), respectively
  },

  filesystem = {
    filtered_items = {
      visible = true,        -- show hidden files by default
      hide_dotfiles = false,
      hide_gitignored = false,
    },
    follow_current_file = { enabled = true },
    hijack_netrw_behavior = "open_default",
    use_libuv_file_watcher = true,
  },

  window = {
    position = "right",  -- 👈 move sidebar to the RIGHT
    width = 32,
    mappings = {
      ["."] = "toggle_hidden",  -- toggle hidden files manually
      ["<space>"] = "toggle_node",
      ["<esc>"] = "cancel",     -- close preview or floating window
      -- ["l"] = "open",
      -- ["h"] = "close_node",
    },
  },
})

-- 🔁 Toggle Neo-tree sidebar with Ctrl + ]
vim.keymap.set("n", "<C-]>", function()
  local neo_tree_win = nil

  -- Check if Neo-tree is currently open
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if bufname:match("neo%-tree filesystem") then
      neo_tree_win = win
      break
    end
  end

  if neo_tree_win then
    -- If already open → close it
    require("neo-tree.command").execute({ action = "close" })
  else
    -- If closed → open it
    require("neo-tree.command").execute({
      toggle = true,
      dir = vim.loop.cwd(),
      source = "filesystem",
      position = "right", -- 👈 also ensure the toggle opens on the right
    })
  end
end, { desc = "Toggle Neo-tree sidebar (open/close)" })
