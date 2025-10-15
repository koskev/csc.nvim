local M = {}

local git = require("csc.git")

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
        if char == ")" then
            paren_depth = paren_depth + 1
        elseif char == "(" then
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
    for i = open_paren + 1, #line do
        local char = line:sub(i, i)
        if char == "(" then
            paren_depth = paren_depth + 1
        elseif char == ")" then
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

local PATTERNS = {
    full = "^(%w+)%(([^)]+)%)(!?): (.+)$",
    no_scope = "^(%w+)(!?): (.+)$",
    breaking_footer = "BREAKING CHANGE: (.+)$",
}

local VALID_TYPES = {
    "feat",
    "fix",
    "docs",
    "style",
    "refactor",
    "test",
    "chore",
    "perf",
    "ci",
    "build",
    "revert",
}

function M.parse_conventional_commit(message)
    if not message or message == "" then
        return nil
    end

    local lines = vim.split(message, "\n")
    local subject = lines[1]

    local commit_type, scope, breaking, description =
        subject:match(PATTERNS.full)

    if commit_type then
        return {
            type = commit_type,
            scope = scope,
            breaking = breaking == "!",
            description = description,
            has_scope = true,
            is_valid = vim.tbl_contains(VALID_TYPES, commit_type),
            raw_subject = subject,
        }
    end

    commit_type, breaking, description = subject:match(PATTERNS.no_scope)

    if commit_type then
        return {
            type = commit_type,
            scope = nil,
            breaking = breaking == "!",
            description = description,
            has_scope = false,
            is_valid = vim.tbl_contains(VALID_TYPES, commit_type),
            raw_subject = subject,
        }
    end

    return nil
end

function M.extract_scopes_from_commits(commits)
    local scope_stats = {}
    local type_stats = {}
    local total_conventional = 0

    for _, commit in ipairs(commits) do
        local parsed = M.parse_conventional_commit(commit.subject)

        if parsed and parsed.is_valid then
            total_conventional = total_conventional + 1

            type_stats[parsed.type] = (type_stats[parsed.type] or 0) + 1

            if parsed.scope and parsed.scope ~= "" then
                scope_stats[parsed.scope] = (scope_stats[parsed.scope] or 0) + 1
            end
        end
    end

    local sorted_scopes = {}
    for scope, count in pairs(scope_stats) do
        table.insert(sorted_scopes, {
            scope = scope,
            count = count,
            frequency = count / total_conventional,
        })
    end

    table.sort(sorted_scopes, function(a, b)
        return a.count > b.count
    end)

    return {
        scopes = sorted_scopes,
        types = type_stats,
        total_commits = #commits,
        conventional_commits = total_conventional,
        conventional_ratio = total_conventional / #commits,
    }
end

local function scope_matches_filters(scope_data, opts)
    if scope_data.count < opts.min_count then
        return false
    end
    if scope_data.frequency < opts.min_frequency then
        return false
    end

    if opts.current_input == "" then
        return true
    end

    local scope = scope_data.scope
    if vim.startswith(scope:lower(), opts.current_input:lower()) then
        return true
    end

    return false
end

local function get_suggestions(commits, opts)
    opts = vim.tbl_extend("force", {
        min_frequency = 0.01, -- 1% minimum frequency
        min_count = 1,
        max_suggestions = 15,
        current_input = "",
    }, opts or {})

    local analysis = M.extract_scopes_from_commits(commits)
    local suggestions = {}

    for _, scope_data in ipairs(analysis.scopes) do
        local scope = scope_data.scope

        if scope_matches_filters(scope_data, opts) then
            table.insert(suggestions, {
                label = scope,
                count = scope_data.count,
                frequency = scope_data.frequency,
                detail = string.format(
                    "Used %d times (%.1f%%)",
                    scope_data.count,
                    scope_data.frequency * 100
                ),
            })

            if #suggestions >= opts.max_suggestions then
                break
            end
        end
    end

    return suggestions
end

M.scope_cache = {
    data = nil,
    timestamp = 0,
    ttl = 30000,
}

function M.get_scope_suggestions(opts, callback)
    opts = opts or {}
    local now = vim.uv.now()

    if
        M.scope_cache.data
        and (now - M.scope_cache.timestamp) < M.scope_cache.ttl
    then
        local suggestions = get_suggestions(M.scope_cache.commits, opts)
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

        local suggestions = get_suggestions(commits, opts)
        callback(nil, suggestions)
    end)
end

function M.validate_commit_message(message)
    local parsed = M.parse_conventional_commit(message)
    local errors = {}
    local warnings = {}

    if not parsed then
        table.insert(errors, "Not a valid conventional commit format")
        table.insert(errors, "Expected: type(scope): description")
        return { valid = false, errors = errors, warnings = warnings }
    end

    if not parsed.is_valid then
        table.insert(
            warnings,
            string.format("'%s' is not a standard commit type", parsed.type)
        )
        table.insert(
            warnings,
            "Standard types: " .. table.concat(VALID_TYPES, ", ")
        )
    end

    if #parsed.description > 50 then
        table.insert(warnings, "Description is longer than 50 characters")
    end

    if parsed.scope and #parsed.scope > 20 then
        table.insert(warnings, "Scope is longer than 20 characters")
    end

    return {
        valid = #errors == 0,
        errors = errors,
        warnings = warnings,
        parsed = parsed,
    }
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

function M.start_cursor_tracking(bufnr, logger)
    local augroup = vim.api.nvim_create_augroup("CSCCursor", { clear = true })

    local last_in_scope = false

    vim.api.nvim_create_autocmd({ "TextChangedI" }, {
        group = augroup,
        buffer = bufnr,
        callback = function()
            local edit_context = M.get_scope_edit_context()
            local currently_in_scope = edit_context.in_scope_parentheses

            if currently_in_scope and not last_in_scope then
                local ok, cmp = pcall(require, "cmp")
                if ok then
                    cmp.complete()
                end
            end

            last_in_scope = currently_in_scope

            if logger and edit_context.in_scope_parentheses then
                local msg = string.format(
                    "In scope: '%s' (partial: '%s')",
                    edit_context.current_scope,
                    edit_context.partial_scope
                )
                logger.log(msg)
            end
        end,
    })
end

return M
