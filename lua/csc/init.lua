local M = {}

M.config = {
	debug = false,
	max_suggestions = 10,
}

M.parser = require("csc.parser")
local git = require('csc.git')

M.initialized_buffers = {}

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

	M.parser.start_cursor_tracking(bufnr, M.logger)

	M.logger.log("CSC plugin active", vim.log.levels.INFO)
end

function M.show_commit_status()
	local bufnr = vim.api.nvim_get_current_buf()
	local status_info = {
		"Commit Scope Status:",
		"",
		"Buffer name: " .. vim.api.nvim_buf_get_name(bufnr),
		"Filetype: " .. vim.bo[bufnr].filetype,
	}

	M.logger.log(
		table.concat(status_info, '\n'),
		vim.log.levels.INFO
	)
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	M.logger = require('csc.logger').setup(M.config)

	-- reset initialized buffers on setup (in case of reload)
	M.initialized_buffers = {}

	-- autocommand for buffer detection
	local augroup = vim.api.nvim_create_augroup(
		'CommitScopeBuffer', { clear = true }
	)

	vim.api.nvim_create_autocmd('FileType', {
		group = augroup,
		pattern = 'gitcommit',
		callback = function(args)
			local bufnr = args.buf

			-- skip if already initialized
			if M.initialized_buffers[bufnr] then
				M.logger.log("Buffer already initialized:" .. bufnr)
				return
			end

			M.logger.log("Detected git commit buffer:" .. vim.api.nvim_buf_get_name(bufnr))
			M.setup_commit_buffer(bufnr)
			M.initialized_buffers[bufnr] = true
		end,
	})

	-- clean up when buffers are deleted
	vim.api.nvim_create_autocmd('BufDelete', {
		group = augroup,
		callback = function(args)
			M.initialized_buffers[args.buf] = nil
		end,
	})

	require('csc.commands').setup(M.logger)

	if pcall(require, 'cmp') then
		require('csc.cmp').register(M.logger)
	elseif pcall(require, 'blink.cmp') then
		require('csc.blink-cmp').set_logger(M.logger)
	else
		M.logger.log("No completion engine found", vim.log.levels.WARN)
	end

	M.logger.log("Plugin setup complete")
end

function M.test_git_integration()
	local callback = function(results)
		local output = {
			"Git Integration Test Results:",
			"",
			"Git available: " .. (results.git_available and "Yes" or "No"),
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

		M.logger.log(table.concat(output, '\n'), vim.log.levels.INFO)
	end

	git.test_git_commands(callback)
end

function M.analyze_repository_scopes()
	M.parser.get_scope_suggestions(
		{ max_suggestions = 50 },
		function(err, suggestions)
			if err then
				M.logger.log(
					"Error analyzing scopes: " .. err, vim.log.levels.ERROR
				)
				return
			end

			if #suggestions == 0 then
				M.logger.log(
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

			M.logger.log(table.concat(lines, '\n'), vim.log.levels.INFO)
		end
	)
end

return M
