local M = {}

local config = require("config")

function M.create_float()
	local buf = vim.api.nvim_create_buf(false, true)

	-- Set options
	vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
	vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
	vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
	vim.api.nvim_set_option_value('buflisted', false, { buf = buf })

	-- Set size
	local width = math.floor(vim.o.columns * config.window.float_width)
	local height = math.floor(vim.o.lines * config.window.float_height)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	-- Create window
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

function M.open_context(float_win, float_buf, src_buf)
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

return M
