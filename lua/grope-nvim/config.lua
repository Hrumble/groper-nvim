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

return config
