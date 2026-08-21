-- Thin loader; the plugin itself lives in lua/herdr-harness/ so it can be
-- required, reloaded and tested without going through this file.
local ok, harness = pcall(require, "herdr-harness")
if not ok then
  return
end

harness.setup({
  -- submit = true would press enter for you. Off by default: sending a
  -- selection is usually the START of a question, not the whole of one.
  submit = false,
  focus_on_send = false,
})
