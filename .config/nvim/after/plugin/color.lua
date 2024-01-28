vim.o.background = "dark" -- or "light" for light mode
-- vim.cmd([[colorscheme gruvbox]])

function Color(color)
    color = color or "gruvbox"
    vim.cmd.colorscheme(color)
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

Color()
