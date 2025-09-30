-- prevent double loading
if vim.g.loaded_commit_scope then
	return
end
vim.g.loaded_commit_scope = 1

if vim.fn.has('nvim-0.8.0') ~= 1 then
	vim.api.nvim_err_writeln('csc.nvim requires Neovim 0.8.0+')
	return
end
