local M = {}

M.config = {
	enabled = true,
	debug = false,
	max_suggestions = 10,
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	vim.api.nvim_create_user_command('CommitScopeTest', function()
		M.test_plugin()
	end, { desc = 'Test commit scope plugin' })

	if M.config.debug then
		M.log("Commit scope plugin loaded with config:", M.config)
	end
end

function M.test_plugin()
	local message = "🎯 Commit Scope Plugin is working!"
	print(message)

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"┌─ Commit Scope Plugin ─┐",
		"│                       │",
		"│ ✅ Plugin is loaded!  │",
		"│                       │",
		"└───────────────────────┘"
	})

	local win = vim.api.nvim_open_win(buf, false, {
		relative = 'editor',
		width = 25,
		height = 5,
		row = math.floor(vim.o.lines / 2) - 2,
		col = math.floor(vim.o.columns / 2) - 12,
		style = 'minimal',
		border = 'rounded'
	})

	-- close after 3 seconds
	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, 3000)
end

-- debug logging helper
function M.log(...)
	if M.config.debug then
		print("[CommitScope]", ...)
	end
end

return M
