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
    vim.keymap.set("n", "gD", function()
      local cur_file = vim.api.nvim_buf_get_name(args.buf)
      local params = vim.lsp.util.make_position_params()
      local function get_enc()
        local clients = (vim.lsp.get_clients or vim.lsp.get_active_clients)({ bufnr = args.buf })
        return clients[1] and clients[1].offset_encoding or "utf-16"
      end
      local function best_loc(locs)
        for _, loc in ipairs(locs) do
          if not vim.uri_to_fname(loc.uri or loc.targetUri):match("%.pyi$") then
            return loc
          end
        end
        return locs[1]
      end
      vim.lsp.buf_request(args.buf, "textDocument/definition", params, function(_, result)
        if not result or #result == 0 then return end
        local first = result[1]
        local first_file = vim.uri_to_fname(first.uri or first.targetUri)
        if first_file == cur_file then
          local range = first.range or first.targetSelectionRange
          local hop2 = { textDocument = { uri = first.uri or first.targetUri }, position = range.start }
          vim.lsp.buf_request(args.buf, "textDocument/definition", hop2, function(_, result2)
            local target = (result2 and #result2 > 0) and best_loc(result2) or first
            vim.lsp.util.jump_to_location(target, get_enc())
          end)
        else
          vim.lsp.util.jump_to_location(best_loc(result), get_enc())
        end
      end)
    end, opts)
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
