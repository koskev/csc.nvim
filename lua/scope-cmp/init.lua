local M = {}

M.config = {
	enabled = true,
	debug = false,
	max_suggestions = 10,
}

function M.is_git_repo(path)
	path = path or vim.fn.getcwd()

	vim.fn.system({ 'git', '-C', path, 'rev-parse', '--git-dir' })
	return vim.v.shell_error == 0
end

-- bufnr (buf number)
function M.is_git_commit_buffer(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local filetype = vim.bo[bufnr].filetype

	local patterns = {
		'COMMIT_EDITMSG$',
		'%.git[/\\]COMMIT_EDITMSG$',
		'git%-rebase%-todo$',
	}

	if filetype == 'gitcommit' then
		return true
	end

	for _, pattern in ipairs(patterns) do
		if bufname:match(pattern) then
			return true
		end
	end

	return false
end

function M.on_buffer_enter(args)
	local bufnr = args.buf

	if not M.is_git_repo() then
		M.log("Not in a git repository")
		return
	end

	if M.is_git_commit_buffer(bufnr) then
		M.log("Detected git commit buffer:", vim.api.nvim_buf_get_name(bufnr))
		M.setup_commit_buffer(bufnr)
	end
end

function M.setup_commit_buffer(bufnr)
	vim.bo[bufnr].textwidth = 72
	vim.bo[bufnr].formatoptions = 'tqn'

	-- add message length indicators
	local wins = vim.fn.win_findbuf(bufnr)
	for _, win in ipairs(wins) do
		vim.wo[win].colorcolumn = '50,72'
	end

	-- also set for future windows showing this buffer
	vim.api.nvim_create_autocmd('BufWinEnter', {
		buffer = bufnr,
		callback = function()
			vim.wo.colorcolumn = '50,72'
		end,
	})

	-- create buffer-local commands
	vim.api.nvim_buf_create_user_command(bufnr, 'CommitScopeStatus', function()
		M.show_commit_status()
	end, { desc = 'Show commit scope plugin status' })

	vim.notify("Commit scope plugin active", vim.log.levels.INFO)
end

function M.show_commit_status()
	local bufnr = vim.api.nvim_get_current_buf()
	local status_info = {
		"Commit Scope Status:",
		"",
		"Git repo: " .. (M.is_git_repo() and "Yes" or "No"),
		"Commit buffer: " .. (M.is_git_commit_buffer(bufnr) and "Yes" or "No"),
		"Buffer name: " .. vim.api.nvim_buf_get_name(bufnr),
		"Filetype: " .. vim.bo[bufnr].filetype,
	}

	vim.notify(table.concat(status_info, '\n'), vim.log.levels.INFO, {
		title = "Commit Scope"
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- autocommand for buffer detection
	local augroup = vim.api.nvim_create_augroup(
		'CommitScopeBuffer', { clear = true }
	)
	vim.api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile', 'BufRead' }, {
		group = augroup,
		callback = M.on_buffer_enter,
	})

	-- enhanced test command
	vim.api.nvim_create_user_command(
		'CommitScopeTest',
		function() M.test_plugin() end,
		{ desc = 'Test commit scope plugin' }
	)

	if M.config.debug then
		M.log("Plugin setup complete")
	end
end

function M.test_plugin()
	local results = {
		"Plugin Test Results:",
		"",
		"Git repo: " .. (M.is_git_repo() and "ye" or "no"),
		"Commit buffer: " .. (M.is_git_commit_buffer() and "ye" or "no"),
	}

	vim.notify(table.concat(results, '\n'), vim.log.levels.INFO)
end

function M.log(...)
	if M.config.debug then
		print("[CommitScope]", ...)
	end
end

return M
