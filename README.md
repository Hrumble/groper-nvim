# GROPER-NVIM
A simple plugin that allows you to live grep on your current buffer.

> [!warning]
> Early stage of development, expect breaking changes.

## Installation

### Lazy

```lua
return {
    'Hrumble/groper-nvim',
    config = function()
        require("groper").setup()
    end
}
```

## Usage

On a buffer you fancy
