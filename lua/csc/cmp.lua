local M = {}

local cmp = require('cmp')
local git = require('csc.git')
local parser = require('csc.parser')

local source = {}

source.config = {
	priority = 100,
	keyword_pattern = [[\k\+]],
	trigger_characters = { '(' }
}

function source:is_available()
	local bufnr = vim.api.nvim_get_current_buf()
	return git.is_git_commit_buffer(bufnr) and git.is_git_repo()
end

function source:get_debug_name()
	return 'CommitScopeCompleter'
end

function source:get_keyword_pattern()
	return source.config.keyword_pattern
end

function source:get_trigger_characters()
	return source.config.trigger_characters
end

function source:complete(params, callback)
	local context = params.context
	local cursor_before_line = context.cursor_before_line

	local scope_context = parser.get_scope_edit_context()

	if not scope_context.in_scope_parentheses then
		callback({})
		return
	end

	-- TODO: buffer textt completions seem to be more often
	-- than used to so maybe check that out
	local current_input = scope_context.partial_scope or ''

	parser.get_scope_suggestions({
		current_input = current_input,
		max_suggestions = 15
	}, function(err, suggestions)
		if err then
			if self.logger then
				self.logger.log("Completion error:", err)
			end
			callback({})
			return
		end

		local items = {}
		for _, suggestion in ipairs(suggestions) do
			table.insert(items, {
				label = suggestion.label,
				kind = cmp.lsp.CompletionItemKind.Text,
				detail = suggestion.detail,
				documentation = {
					kind = 'markdown',
					value = string.format('**%s**\n\n%s\n\nFrequency: %.1f%% (%d uses)',
						suggestion.label,
						'Scope from commit history',
						suggestion.frequency * 100,
						suggestion.count
					)
				},
				insertText = suggestion.label,
				filterText = suggestion.label,
				sortText = string.format("%04d_%s", 1000 - suggestion.count, suggestion.label),
			})
		end

		callback(items)
	end)
end

function M.setup(logger)
	source.logger = logger
	cmp.register_source('csc', source)

	vim.api.nvim_create_autocmd('FileType', {
		pattern = 'gitcommit',
		callback = function()
			local config = cmp.get_config()

			local sources = config.sources or {
				{ name = 'nvim_lsp' },
				{ name = 'luasnip' },
				{ name = 'buffer' },
				{ name = 'path' },
			}

			-- add our source with high priority at the beginning
			-- but only if it's not already there
			local has_commit_scope = false
			for _, s in ipairs(sources) do
				if s.name == 'csc' then
					has_commit_scope = true
					break
				end
			end

			if not has_commit_scope then
				table.insert(sources, 1, { name = 'csc', priority = 100 })
			end

			-- apply the extended configuration
			cmp.setup.buffer({
				sources = sources
			})
		end
	})
end

return M
