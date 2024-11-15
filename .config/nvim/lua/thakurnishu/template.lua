vim.api.nvim_create_user_command("HtmlBoilerplate", function()
  local boilerplate = [[
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Document</title>
</head>
<body>
    
</body>
</html>
]]
  vim.api.nvim_put(vim.split(boilerplate, "\n"), "l", true, true)
end, {})
