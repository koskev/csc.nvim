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
    └── csc.lua        # Plugin initialization
```

## Development

The plugin uses:
- Async git operations via `jobstart`
- nvim-cmp custom source API
- Conventional commit regex patterns
- Scope frequency analysis

### Commands

- `:CSC test` - Test plugin functionality
- `:CSC test_git` - Test git integration
- `:CSC analyze` - Analyze repository scope usage
- `:CSC status` - Show current buffer status
- `:CSC help` - Display available commands

## License

## TODOs:
- TODO: add license
- TODO: do versioning
- TODO: confirm installation instructions
- TODO: make it so this can be installed as a dependency of nvim-cmp

