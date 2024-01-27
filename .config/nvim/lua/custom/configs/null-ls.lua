local null_ls = require("null_ls")
local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
local opts = {
  sources = {
    null_ls.builtins.formating.gofumpt,
    null_ls.builtins.formating.goimports_reviser,
    null_ls.builtins.formating.golines,
  },
  on_attach = function (client, bufrn)
    if client.supports_method("textDocuments/formatting") then
      vim.api.nvim_clear_autocmds({
        group = augroup,
        buffer = bufrn,
      })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        buffer = bufrn,
        callback = function()
          vim.lsp.buf.format({bufrn = bufrn})
        end,
      })
    end
  end,
}
return opts
