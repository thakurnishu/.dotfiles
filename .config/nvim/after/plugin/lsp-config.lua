local lsp_zero = require('lsp-zero')
require('lspconfig').ansiblels.setup({})
require('lspconfig').azure_pipelines_ls.setup({})
require('lspconfig').bashls.setup({})
require('lspconfig').clangd.setup({})
require('lspconfig').dockerls.setup({})
require('lspconfig').dotls.setup({})
require('lspconfig').groovyls.setup({})
require('lspconfig').helm_ls.setup({})
require('lspconfig').jsonls.setup({})
require('lspconfig').lua_ls.setup({})
require('lspconfig').marksman.setup({})
require('lspconfig').sqls.setup({})
require('lspconfig').terraformls.setup({})
require('lspconfig').yamlls.setup({})
require('lspconfig').gopls.setup({})
require('lspconfig').htmx.setup({})
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
require'lspconfig'.html.setup {
  capabilities = capabilities,
}


--- cmp_mappings['<Tab>'] = nil (tab) to disable
--- cmp_mappings['<S-Tab>'] = nil (shift+tab) to disable
--
local cmp = require('cmp')
-- local cmp_action = require('lsp-zero').cmp_action()
local cmp_select = {behavior = cmp.SelectBehavior.Select}
local cmp_mappings = cmp.mapping.preset.insert {
    ['<S-Tab>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<Tab>'] = cmp.mapping.select_next_item(cmp_select),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
}
cmp.setup({
    mapping = cmp_mappings,
    sources = {
        {name = 'nvim_lsp'},
    }
})

lsp_zero.set_preferences({
    suggest_lsp_servers = false,
    sign_icons = {
        error = 'E',
        warn = 'W',
        hint = 'H',
        info = 'I'
    }
})

lsp_zero.on_attach(function(client, bufnr)
    local opts = {buffer = bufnr, remap = false}

    vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
    vim.keymap.set("n", "I", function() vim.lsp.buf.hover() end, opts)
    vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
    vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
    vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
    vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
    vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
    vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end, opts)
    vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)
end)

lsp_zero.setup()

vim.diagnostic.config({
    virtual_text = true
})
