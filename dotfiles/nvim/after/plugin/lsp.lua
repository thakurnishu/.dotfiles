local ls_servers = {
  "lua_ls",
  "gopls",
  "terraformls",
  "dockerls",
  "ansiblels",
  "jsonls",
  "yamlls",
  "taplo",
  "marksman",
  "pyright",
  "tflint",
  "angularls",
  "ts_ls",
  "html",
  "phpactor"
}

require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed = ls_servers })
local cmp_nvim_lsp = require("cmp_nvim_lsp")

local capabilities = cmp_nvim_lsp.default_capabilities()

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf, remap = false }
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "I", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gy", vim.lsp.buf.type_definition, opts)
    vim.keymap.set("n", "<leader>vd", function()
      local ok, builtin = pcall(require, "telescope.builtin")
      if ok then builtin.lsp_definitions() return end
      vim.lsp.buf.definition()
    end, opts)
    vim.keymap.set("n", "<leader>vws", vim.lsp.buf.workspace_symbol, opts)
    vim.keymap.set("n", "<leader>vf", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "<leader>vca", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "<leader>vrr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>vrn", vim.lsp.buf.rename, opts)
    vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
  end
})

vim.lsp.config('*', {
  capabilities = capabilities,
})

vim.lsp.enable(ls_servers)
