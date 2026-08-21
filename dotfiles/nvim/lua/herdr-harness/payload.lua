-- Turning what is on screen into text worth sending.
--
-- Everything carries WHERE it came from, because the harness has its own file
-- tools: given `src/thing.ts:40-58` it can open the file, read around the
-- selection, and edit it. Sending bare code throws that away.
local M = {}

--- Path relative to nvim's cwd, which in a herdr space is the workspace root.
--- Shorter to read, and it is the form the harnesses' own tools expect.
local function relpath(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr or 0)
  if name == "" then
    return nil
  end
  return vim.fn.fnamemodify(name, ":.")
end

M.relpath = relpath

--- The visual selection, as text plus its line range.
--- Called from a visual-mode mapping, so the selection is still live: "v" is
--- the anchor and "." the cursor. getregion handles charwise/linewise/blockwise
--- for us rather than us reimplementing the column arithmetic.
function M.selection()
  local mode = vim.fn.mode()
  if not mode:match("^[vV\22]") then
    return nil, "not in visual mode"
  end

  local anchor = vim.fn.getpos("v")
  local cursor = vim.fn.getpos(".")
  local lines = vim.fn.getregion(anchor, cursor, { type = mode })
  if not lines or #lines == 0 then
    return nil, "empty selection"
  end

  local first = math.min(anchor[2], cursor[2])
  local last = math.max(anchor[2], cursor[2])

  return {
    text = table.concat(lines, "\n"),
    path = relpath(),
    first = first,
    last = last,
  }
end

--- A reference to the whole current buffer.
function M.buffer()
  local path = relpath()
  if not path then
    return nil, "buffer has no file"
  end
  return { path = path }
end

--- The file under the cursor in a tree buffer (neo-tree, oil, netrw...).
--- Each tree plugin exposes its own API, so ask them in turn and fall back to
--- <cfile>, which covers netrw and anything else that puts a path on the line.
function M.tree_file()
  local ok, api = pcall(require, "neo-tree.sources.manager")
  if ok then
    local state = api.get_state("filesystem")
    local node = state and state.tree and state.tree:get_node()
    if node and node.path then
      return { path = vim.fn.fnamemodify(node.path, ":.") }
    end
  end

  local oil_ok, oil = pcall(require, "oil")
  if oil_ok then
    local entry = oil.get_cursor_entry()
    local dir = oil.get_current_dir()
    if entry and dir then
      return { path = vim.fn.fnamemodify(dir .. entry.name, ":.") }
    end
  end

  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" then
    return { path = vim.fn.fnamemodify(cfile, ":.") }
  end
  return nil, "no file under the cursor"
end

--- Render a payload for the harness.
--- A fenced block for code, a bare @path for a reference. The blank line
--- matters: several harness TUIs treat the first line as the prompt.
function M.format(p)
  if p.text then
    local where = p.path and string.format("%s:%d-%d", p.path, p.first, p.last) or "selection"
    return string.format("%s\n\n```\n%s\n```\n", where, p.text)
  end
  return string.format("@%s ", p.path)
end

return M
