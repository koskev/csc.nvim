local M = {}

-- subcommands
Subs = {
	test = {
		desc = "Basic plugin test",
		run = function(_) require('csc').test_plugin() end,
	},
	test_git = {
		desc = "Test git integration",
		run = function(_) require('csc').test_git_integration() end,
	},
	analyze = {
		desc = "Analyze repository scopes",
		run = function(_) require('csc').analyze_repository_scopes() end,
	},
	status = {
		desc = "Show status for current buffer",
		run = function(_) require('csc').show_commit_status() end,
	},
	help = {
		desc = "Show this help",
		run = function(_)
			local lines = { "CSC subcommands:" }
			for name, s in pairs(Subs) do
				table.insert(lines, ("  %-9s — %s"):format(name, s.desc))
			end

			if M.logger then
				M.logger.log(
					table.concat(lines, "\n"),
					vim.log.levels.INFO
				)
			end
		end,
	},
}

local function complete_sub(_, line)
	local arg = line:match("^%S+%s+(%S*)$") or ""
	local out = {}
	for name, _ in pairs(Subs) do
		if name:find("^" .. vim.pesc(arg)) then table.insert(out, name) end
	end
	table.sort(out)
	return out
end

function M.setup(logger)
	M.logger = logger

	vim.api.nvim_create_user_command(
		"CSC",
		function(opts)
			local sub = (opts.fargs[1] or "help"):lower()
			local cmd = Subs[sub]
			if not cmd then
				if M.logger then
					M.logger.log(
						("CSC: unknown subcommand '%s'"):format(sub),
						vim.log.levels.WARN
					)
				end
				Subs.help.run()
				return
			end
			cmd.run(opts)
		end,
		{
			desc = "Commit Scope Completion (csc.nvim) dispatcher",
			nargs = "*",
			complete = complete_sub
		}
	)
end

return M
