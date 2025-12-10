# GROPER-NVIM
A simple plugin that allows you to live grep on your current buffer.

> [!warning]
> Early stage of development, expect breaking changes, and a broken plugin while we're at it.

## Installation

### Lazy

```lua
return {
    'Hrumble/groper-nvim',
    config = function()
        require("grope-nvim").setup({
            -- Config goes here, see #Configuration
        })
        
        local grope = require("grope-nvim")
        -- Set keymap to trigger grep window
        keymap.set("n", "<leader>gg", function() grope.live_grep() end)
    end
}
```

## Usage

On a buffer you fancy, use `require("grope-nvim").live_grep()` to open up the live grep window, the top line is where your input goes, below are the results.

## Configuration

These are all the default values, unless specified otherwise, the following parameters will take the following values:
```lua
require("grope-nvim").setup({
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
})
```
