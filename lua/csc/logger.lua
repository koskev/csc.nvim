local M = {}

M.config = { debug = false }

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})
	return M
end

function M.log(msg, level, opts)
	if level then
		opts = opts or {}
		opts.title = "csc.nvim"
		vim.notify(msg, level, opts)

	elseif M.config.debug then
		print("[csc.nvim]", msg)
	end
end

return M
