local M = {}

function M.run_git_command(args, opts, callback)
	opts = opts or {}

	local cmd = { 'git' }
	vim.list_extend(cmd, args)

	local stdout_data = {}
	local stderr_data = {}

	local job_id = vim.fn.jobstart(cmd, {
		cwd = opts.cwd or vim.fn.getcwd(),
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data)
			for _, line in ipairs(data) do
				if line ~= '' then
					table.insert(stdout_data, line)
				end
			end
		end,
		on_stderr = function(_, data)
			vim.list_extend(stderr_data, data)
		end,
		on_exit = function(_, exit_code)
			if exit_code == 0 then
				callback(nil, stdout_data)
			else
				local error_msg = table.concat(stderr_data, '\n')
				callback(error_msg ~= '' and error_msg or 'Git command failed', nil)
			end
		end,
	})

	if job_id == 0 then
		callback('Failed to start git command', nil)
	elseif job_id == -1 then
		callback('Git command not executable', nil)
	end

	return job_id
end

function M.get_git_root(callback)
	M.run_git_command(
		{ 'rev-parse', '--show-toplevel' },
		{},
		function(err, output)
			if err then
				callback(err, nil)
			else
				local root = output[1] and vim.trim(output[1]) or nil
				callback(nil, root)
			end
		end
	)
end

function M.get_git_log(opts, callback)
	opts = vim.tbl_extend('force', {
		max_count = 100,
		format = '%H|%s|%an|%ad',
		date_format = 'short',
	}, opts or {})

	local args = {
		'log',
		'--pretty=format:' .. opts.format,
		'--date=' .. opts.date_format,
		'-n', tostring(opts.max_count)
	}

	M.run_git_command(
		args,
		{},
		function(err, output)
			if err then
				callback(err, nil)
				return
			end

			local commits = {}
			for _, line in ipairs(output) do
				if line and line ~= '' then
					local parts = vim.split(line, '|')
					if #parts >= 4 then
						table.insert(commits, {
							hash = parts[1],
							subject = parts[2],
							author = parts[3],
							date = parts[4],
						})
					end
				end
			end

			callback(nil, commits)
		end
	)
end

function M.test_git_commands(callback)
	local results = {
		git_available = false,
		in_repo = false,
		git_root = nil,
		recent_commits = {},
	}

	M.run_git_command(
		{ '--version' },
		{},
		function(err, output)
			results.git_available = not err

			if err then
				callback(results)
				return
			end

			M.get_git_root(function(err, root)
				results.git_root = root

				M.get_git_log({ max_count = 5 }, function(err, commits)
					if not err then
						results.recent_commits = commits
					end
					callback(results)
				end)
			end)
		end
	)
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

return M
