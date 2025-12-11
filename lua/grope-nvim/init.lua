local M = {}

local config = {
	-- Options for the context window
	context_window = {
		context_before = 5,   -- Number of context lines to show before the matching line
		context_after = 5,		-- Number of context lines to show after the matching line
		context_width = 0.5, 	-- Context width size
		keys = {
			open_context = "l", -- Open Context window
			close_context = "q" -- Close context window
		}
	},

	-- Options for the general window
	window = {
		float_width = 0.7,  	-- Window Width size
		float_height = 0.6, 	-- Window Height size
		keys = {
			goto = "<CR>"				-- Goto line number in buffer
		}
	}
}

function M.setup(opts)
	if opts then
		for k, v in pairs(opts) do
			config[k] = v
		end
	end
end

local function create_float()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
	vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
	vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
	vim.api.nvim_set_option_value('buflisted', false, { buf = buf })

	local width = math.floor(vim.o.columns * config.window.float_width)
	local height = math.floor(vim.o.lines * config.window.float_height)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	local win = vim.api.nvim_open_win(buf, true, {
		relative = 'editor',
		width = width,
		height = height,
		row = row,
		col = col,
		style = 'minimal',
		border = 'rounded',
	})

	vim.api.nvim_set_option_value('cursorline', true, { win = win })
	return buf, win
end

local function open_context(float_win, float_buf, src_buf)
	local row = vim.api.nvim_win_get_cursor(float_win)[1]
			if row < 1 then return end

			local text = vim.api.nvim_buf_get_lines(float_buf, row - 1, row, false)[1] or ""
			local orig_num = tonumber(text:match("^(%d+):"))
			if not orig_num then return end

			local src_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)
			local start_line = math.max(orig_num - config.context_window.context_before - 1, 0)
			local end_line = math.min(orig_num + config.context_window.context_after, #src_lines)

			local lines = {}
			for i = start_line + 1, end_line do
				table.insert(lines, src_lines[i])
			end

			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
			vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
			vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
			vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
			vim.api.nvim_set_option_value('filetype', vim.api.nvim_get_option_value('filetype', { buf = buf }), { buf = buf })

			local width = math.floor(vim.o.columns * config.context_window.context_width)
			local height = #lines
			local row_win = math.floor((vim.o.lines - height) / 2)
			local col_win = math.floor((vim.o.columns - width) / 2)

			local win = vim.api.nvim_open_win(buf, true, {
				relative = "editor",
				width = width,
				height = height,
				row = row_win,
				col = col_win,
				style = "minimal",
				border = "rounded",
			})

			-- place cursor on the matched line
			local cursor_line = orig_num - start_line
			if cursor_line < 1 then cursor_line = 1 end
			vim.api.nvim_win_set_cursor(win, { cursor_line, 0 })

			-- highlight the matched line
			local ns = vim.api.nvim_create_namespace("grep_context_highlight")
			vim.api.nvim_buf_add_highlight(buf, ns, "Visual", cursor_line - 1, 0, -1)

			-- close context window on <Esc> or q
			local close_fn = function()
				if vim.api.nvim_win_is_valid(win) then
					vim.api.nvim_win_close(win, true)
				end
			end
			vim.keymap.set("n", "<Esc>", close_fn, { buffer = buf, noremap = true, silent = true })
			vim.keymap.set("n", config.context_window.keys.close_context, close_fn, { buffer = buf, noremap = true, silent = true })
end

-- Live grepping with syntax highlighting
function M.live_grep()
	local src_buf = vim.api.nvim_get_current_buf()
	local src_ft = vim.api.nvim_get_option_value('filetype', { buf = src_buf })
	local all_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)

	local float_buf, float_win = create_float()
	vim.api.nvim_set_option_value("modifiable", true, { buf = float_buf })
	-- set filetype same as source for syntax highlighting
	vim.api.nvim_set_option_value('filetype', src_ft, { buf = float_buf })

	-- first line reserved for input
	vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, { "" })
	vim.api.nvim_win_set_cursor(float_win, { 1, 0 })

	local ns_input = vim.api.nvim_create_namespace("grep_float_input_hl")

	local function update_results()
		local pattern = vim.api.nvim_buf_get_lines(float_buf, 0, 1, false)[1] or ""

		-- get old cursor pos to restore after update
		local cur = vim.api.nvim_win_get_cursor(float_win)

		-- clear old results, starting from line 1 (leave input line)
		vim.api.nvim_set_option_value("modifiable", true, { buf = float_buf })
		vim.api.nvim_buf_set_lines(float_buf, 1, -1, false, {})

		local out = {}
		for i, line in ipairs(all_lines) do
			if pattern ~= "" and line:match(pattern) then
				table.insert(out, i .. ": " .. line)
			end
		end

		vim.api.nvim_buf_set_lines(float_buf, 1, -1, false, out)
		-- keep input line modifiable
		vim.api.nvim_set_option_value("modifiable", true, { buf = float_buf })

		-- restore cursor so typing continues
		vim.api.nvim_win_set_cursor(float_win, cur)
	end

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		buffer = float_buf,
		callback = update_results,
	})

	vim.keymap.set("n", config.window.keys.goto, function()
		local row = vim.api.nvim_win_get_cursor(float_win)[1]
		if row < 1 then return end
		local text = vim.api.nvim_buf_get_lines(float_buf, row - 1, row, false)[1]
		if not text then return end
		local num = tonumber(text:match("^(%d+):"))
		if not num then return end
		vim.api.nvim_win_close(float_win, true)
		vim.api.nvim_set_current_buf(src_buf)
		vim.api.nvim_win_set_cursor(0, { num, 0 })
	end, { buffer = float_buf })

	vim.keymap.set("n", "<Esc>", function()
		if vim.api.nvim_win_is_valid(float_win) then
			vim.api.nvim_win_close(float_win, true)
		end
	end, { buffer = float_buf })

	vim.keymap.set("n", config.context_window.keys.open_context, function()
		open_context(float_win, float_buf, src_buf)
	end, { buffer = float_buf })
end


return M
