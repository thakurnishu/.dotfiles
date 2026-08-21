-- Thin loader; the plugin itself lives in lua/herdr-harness/ so it can be
-- required, reloaded and tested without going through this file.
local ok, harness = pcall(require, "herdr-harness")
if not ok then
  return
end

harness.setup({
  -- submit = true would press enter for you. Off by default: sending a
  -- selection is usually the START of a question, not the whole of one --
  -- which is also why focus_on_send is on. You are taken to the harness with
  -- the code already typed in, ready to say what you want done with it.
  submit = false,
  focus_on_send = true,
})
