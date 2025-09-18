local M = {}

M.config = { debug = false }

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	return M
end

function M.log(...)
	if M.config.debug then
		print("[CommitScope]", ...)
	end
end

return M
