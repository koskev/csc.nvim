-- prevent double loading
if vim.g.loaded_commit_scope then
	return
end
vim.g.loaded_commit_scope = 1

-- version check ?
if vim.fn.has('nvim-0.8.0') ~= 1 then
	vim.api.nvim_err_writeln('commit-scope.nvim requires Neovim 0.8.0+')
	return
end

-- basic keymap to test plugin loading
vim.keymap.set('n', '<leader>ct', '<cmd>CommitScopeTest<cr>', {
	desc = 'Test commit scope plugin'
})
