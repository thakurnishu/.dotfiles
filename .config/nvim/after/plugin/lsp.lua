local ls_servers = {
  "lua_ls",
  "gopls",
  "terraformls"
}

require("mason").setup()
require("mason-lspconfig").setup({ ensure_installed =  ls_servers })
local lsp_config = require('lspconfig')
local cmp_nvim_lsp = require("cmp_nvim_lsp")  -- Access completion capabilities

local capabilities = cmp_nvim_lsp.default_capabilities()

local on_attach = function(_, bufr)
  local opts = {buffer = bufr, remap = false}
  vim.keymap.set("n", "<leader>rn", function() vim.lsp.bug.rename() end, opts)
  vim.keymap.set("n", "I", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end


for _, server in ipairs(ls_servers) do
  lsp_config[server].setup({
    on_attach = on_attach,
    capabilities = capabilities
  })
end
