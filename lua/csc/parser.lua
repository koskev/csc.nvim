local M = {}

function M.get_cursor_context()
	local cursor_pos = vim.api.nvim_win_get_cursor(0)
	local line_num = cursor_pos[1]
	local col_num = cursor_pos[2]

	local line = vim.api.nvim_get_current_line()

	return {
		line = line,
		col = col_num,
		line_num = line_num,
		char_under_cursor = line:sub(col_num, col_num),
		before_cursor = line:sub(1, col_num - 1),
		after_cursor = line:sub(col_num + 1),
	}
end

function M.find_scope_context(line, col)
	if not line or col > #line then
		return nil
	end

	local open_paren = nil
	local paren_depth = 0

	-- find open paren
	for i = col, 1, -1 do
		local char = line:sub(i, i)
		if char == ')' then
			paren_depth = paren_depth + 1
		elseif char == '(' then
			-- if outermost
			if paren_depth == 0 then
				open_paren = i
				break
			else
				paren_depth = paren_depth - 1
			end
		end
	end

	if not open_paren then
		return nil
	end

	local close_paren = nil
	paren_depth = 0

	-- find close paren
	for i = col, #line do
		local char = line:sub(i, i)
		if char == '(' then
			paren_depth = paren_depth + 1
		elseif char == ')' then
			if paren_depth == 0 then
				close_paren = i
				break
			else
				paren_depth = paren_depth - 1
			end
		end
	end

	if not close_paren then
		return nil
	end

	local content = line:sub(open_paren + 1, close_paren - 1)
	local cursor_offset = col - open_paren

	return {
		content = content,
		start_pos = open_paren,
		end_pos = close_paren,
		cursor_offset = cursor_offset,
		is_inside = cursor_offset >= 0 and cursor_offset <= #content,
		partial_scope = content:sub(1, cursor_offset),
	}
end

function M.parse_conventional_commit(line)
	if not line or line == '' then
		return nil
	end

	-- pattern: type(scope): description
	local type_pattern = '^(%w+)%(([^)]*)%)(!?): (.+)$'
	local commit_type, scope, breaking, description = line:match(type_pattern)

	if commit_type then
		return {
			type = commit_type,
			scope = scope,
			breaking = breaking == '!',
			description = description,
			has_scope = true,
			format = 'full'
		}
	end

	-- pattern: type: description (no scope)
	local no_scope_pattern = '^(%w+)(!?): (.+)$'
	commit_type, breaking, description = line:match(no_scope_pattern)

	if commit_type then
		return {
			type = commit_type,
			scope = nil,
			breaking = breaking == '!',
			description = description,
			has_scope = false,
			format = 'no_scope'
		}
	end

	return nil
end

function M.get_scope_edit_context()
	local context = M.get_cursor_context()
	local line = context.line
	local col = context.col

	local commit_info = M.parse_conventional_commit(line)
	local scope_context = M.find_scope_context(line, col)

	if scope_context and scope_context.is_inside then
		return {
			in_scope_parentheses = true,
			current_scope = scope_context.content,
			partial_scope = scope_context.partial_scope,
			scope_start = scope_context.start_pos,
			scope_end = scope_context.end_pos,
			commit_info = commit_info,
			context = context,
		}
	end

	return {
		in_scope_parentheses = false,
		commit_info = commit_info,
		context = context,
	}
end

function M.start_cursor_tracking(bufnr, config)
	local augroup = vim.api.nvim_create_augroup(
		'CommitScopeCursor', { clear = true }
	)

	vim.api.nvim_create_autocmd({ 'CursorMovedI', 'TextChangedI' }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			local edit_context = M.get_scope_edit_context()

			if config.debug and edit_context.in_scope_parentheses then
				local msg = string.format("In scope: '%s' (partial: '%s')",
					edit_context.current_scope,
					edit_context.partial_scope)
				vim.notify(msg, vim.log.levels.INFO)
			end
		end,
	})
end

return M
