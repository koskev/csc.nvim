local M = {}

M.config = {
	enabled = true,
	debug = false,
	max_suggestions = 10,
}

M.parser = require("csc.parser")
local git = require('csc.git')

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

	M.parser.start_cursor_tracking(bufnr, M.config)

	-- create buffer-local commands
	vim.api.nvim_buf_create_user_command(
		bufnr, 'CommitScopeStatus',
		function()
			M.show_commit_status()
		end,
		{ desc = 'Show commit scope plugin status' }
	)

	vim.api.nvim_buf_create_user_command(
		bufnr, 'CommitScopeContext',
		function()
			local edit_context = M.parser.get_scope_edit_context()
			print(vim.inspect(edit_context))
		end,
		{ desc = 'Show current scope context' }
	)

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

	-- TODO: maybe rename all these CommitScope things to CSC

	-- new command to test git
	vim.api.nvim_create_user_command(
		'CommitScopeTestGit',
		function()
			M.test_git_integration()
		end,
		{ desc = 'Test git integration' }
	)

	vim.api.nvim_create_user_command(
		'CommitScopeAnalyze',
		function()
			M.analyze_repository_scopes()
		end,
		{ desc = 'Analyze repository scopes' }
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

function M.test_git_integration()
	local callback = function(results)
		local output = {
			"Git Integration Test Results:",
			"",
			"Git available: " .. (results.git_available and "ye" or "no"),
			"In git repo: " .. (results.in_repo and "ye" or "no"),
		}

		if results.git_root then
			table.insert(output, "Git root: " .. results.git_root)
		end

		if #results.recent_commits > 0 then
			table.insert(output, "")
			table.insert(output, "Recent commits:")
			for i, commit in ipairs(results.recent_commits) do
				if i <= 3 then
					table.insert(output, string.format("- %s: %s",
						commit.hash:sub(1, 7),
						commit.subject:sub(1, 50)))
				end
			end
		end

		vim.notify(table.concat(output, '\n'), vim.log.levels.INFO)
	end

	git.test_git_commands(callback)
end

function M.log(...)
	if M.config.debug then
		print("[CommitScope]", ...)
	end
end

M.scope_cache = {
	data = nil,
	timestamp = 0,
	ttl = 30000
}

function M.get_scope_suggestions(opts, callback)
	opts = opts or {}
	local now = vim.uv.now()

	if M.scope_cache.data and
		(now - M.scope_cache.timestamp) < M.scope_cache.ttl
	then
		local suggestions = M.parser.get_scope_suggestions(
			M.scope_cache.commits, opts
		)
		callback(nil, suggestions)
		return
	end

	git.get_git_log({ max_count = 200 }, function(err, commits)
		if err then
			callback(err, nil)
			return
		end

		M.scope_cache.data = true
		M.scope_cache.commits = commits
		M.scope_cache.timestamp = now

		local suggestions = M.parser.get_scope_suggestions(commits, opts)
		callback(nil, suggestions)
	end)
end

function M.analyze_repository_scopes()
	M.get_scope_suggestions(
		{ max_suggestions = 50 },
		function(err, suggestions)
			if err then
				vim.notify(
					"Error analyzing scopes: " .. err, vim.log.levels.ERROR
				)
				return
			end

			if #suggestions == 0 then
				vim.notify(
					"No scopes found in commit history", vim.log.levels.WARN
				)
				return
			end

			local lines = { "Repository Scope Analysis:", "" }

			for i, suggestion in ipairs(suggestions) do
				if i <= 10 then
					local lbl = suggestion.label
					local dtl = suggestion.detail

					table.insert(
						lines,
						string.format("  %d. %s - %s", i, lbl, dtl)
					)
				end
			end

			if #suggestions > 10 then
				table.insert(
					lines,
					string.format("  ... and %d more", #suggestions - 10)
				)
			end

			vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
		end
	)
end

return M
