# Developer Documentation

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

## Architecture Overview

The plugin uses:
- Async git operations via `jobstart` for non-blocking performance
- nvim-cmp custom source API for completion integration
- Conventional commit regex patterns for parsing
- Scope frequency analysis for intelligent suggestions

## How It Works

1. **Buffer Detection**: Monitors git commit buffers (`COMMIT_EDITMSG`)
2. **History Parsing**: Parses commit history for conventional commit patterns
3. **Scope Extraction**: Extracts and ranks scopes by frequency
4. **Context Detection**: Provides suggestions only when cursor is within scope parentheses
5. **Performance**: Caches results with 30-second TTL to avoid repeated git operations

## Debug Commands

These commands are available for debugging and development:

- `:CSC test_git` - Test git integration
- `:CSC analyze` - Analyze repository scope usage
- `:CSC status` - Show current buffer status
- `:CSC help` - Display available commands

## Cache Behavior

- Cache TTL: 30 seconds (hardcoded, see TODO.md)
- Storage: In-memory Lua table

## nvim-cmp Integration

The plugin registers as a completion source with:
- Trigger: Inside parentheses after commit type
- Pattern: `type(|)` or `type(|)!`
- Fuzzy matching: Handled by nvim-cmp
- Priority: Determined by frequency in commit history

## Git Operations

- Uses `git log` with custom formatting
- Processes max 100 commits (hardcoded, see TODO.md)
- Runs asynchronously to avoid blocking
- Falls back gracefully if not in git repository
