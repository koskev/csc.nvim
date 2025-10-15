-- prevent double loading
if vim.g.loaded_commit_scope then
    return
end
vim.g.loaded_commit_scope = 1

if vim.fn.has("nvim-0.8.0") ~= 1 then
    vim.api.nvim_err_writeln("csc.nvim requires Neovim 0.8.0+")
    return
end

if pcall(require, "blink.cmp") then
    require("blink.cmp").add_source_provider(
        "csc",
        { module = "csc.blink-cmp", name = "csc" }
    )
    require("blink.cmp").add_filetype_source("gitcommit", "csc")
end
