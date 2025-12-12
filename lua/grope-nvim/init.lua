local M = {}

local config = require("groper.config")
local window = require("window")

function M.setup(opts)
	if opts then
		for k, v in pairs(opts) do
			config[k] = v
		end
	end
end

-- Live grepping with syntax highlighting
function M.live_grep()
	local src_buf = vim.api.nvim_get_current_buf()
	local src_ft = vim.api.nvim_get_option_value('filetype', { buf = src_buf })
	local all_lines = vim.api.nvim_buf_get_lines(src_buf, 0, -1, false)

	local float_buf, float_win = window.create_float()
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
		window.open_context(float_win, float_buf, src_buf)
	end, { buffer = float_buf })
end


return M
