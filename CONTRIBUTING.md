## Project Structure

```
├── lua/csc/
│   ├── init.lua       # Main plugin logic
│   ├── parser.lua     # Commit message parsing
│   ├── git.lua        # Git integration
│   ├── cmp.lua        # nvim-cmp source
│   ├── commands.lua   # User commands
│   └── logger.lua     # Debug logging
└── plugin/
    └── csc.lua        # Version check; no autoload
```

## Development

The plugin uses:
- Async git operations via `jobstart`
- nvim-cmp custom source API
- Conventional commit regex patterns
- Scope frequency analysis

## How It Works

1. Monitors git commit buffers (`COMMIT_EDITMSG`)
2. Parses commit history for conventional commit patterns
3. Extracts and ranks scopes by frequency
4. Provides contextual suggestions when cursor is within scope parentheses
5. Caches results for performance (30-second TTL)

### Commands

- `:CSC test` - Test plugin functionality
- `:CSC test_git` - Test git integration
- `:CSC analyze` - Analyze repository scope usage
- `:CSC status` - Show current buffer status
- `:CSC help` - Display available commands

## License

## TODOs:
- TODO: add license
- TODO: confirm installation instructions
- TODO: make cache TTL configurable
- TODO: update README Troubleshooting section to include configurable TTL
