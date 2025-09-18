local M = {}

M.config = { debug = false }

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	return M
end

function M.log(msg, level, opts)
	if M.config.debug then
		print("[CSC]", msg)
	end

	if level then
		vim.notify(msg, level, opts)
	end
end

return M
