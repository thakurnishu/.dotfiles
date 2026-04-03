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

local on_attach = function(_, bufr)
  local opts = {buffer = bufr, remap = false}
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("n", "I", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>vf", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end

vim.lsp.config('*', {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.enable(ls_servers)
