# csc.nvim

Commit Scope Completer - intelligent scope suggestions for conventional commits in Neovim.

## Features

- **Smart Autocompletion**: Analyzes your repository's commit history to suggest relevant scopes
- **nvim-cmp Integration**: Seamless integration with nvim-cmp for autocompletion
- **Conventional Commit Support**: Built for the [Conventional Commits](https://www.conventionalcommits.org/) specification
- **Context-Aware**: Only triggers within scope parentheses `type(|): description`
- **Frequency-Based Ranking**: Suggests scopes based on historical usage patterns

## Requirements

- Neovim 0.8.0+
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)
- Git repository

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yus-works/csc.nvim',
  dependencies = { 'hrsh7th/nvim-cmp' },
  config = function()
    require('csc').setup({
      enabled = true,
      debug = false,
      max_suggestions = 10,
    })
  end,
}
```

## Usage

The plugin automatically activates when editing git commit messages. Start typing a conventional commit and get scope suggestions:

```
feat(|): add new feature
     ^ cursor here triggers scope suggestions
```

### Commands

- `:CSC test` - Test plugin functionality
- `:CSC test_git` - Test git integration
- `:CSC analyze` - Analyze repository scope usage
- `:CSC status` - Show current buffer status
- `:CSC help` - Display available commands

## How It Works

1. Monitors git commit buffers (`COMMIT_EDITMSG`)
2. Parses commit history for conventional commit patterns
3. Extracts and ranks scopes by frequency
4. Provides contextual suggestions when cursor is within scope parentheses
5. Caches results for performance (30-second TTL)

## Configuration

```lua
require('csc').setup({
  enabled = true,          -- Enable/disable the plugin
  debug = false,           -- Show debug messages
  max_suggestions = 10,    -- Maximum number of suggestions
})
```

## Conventional Commit Format

The plugin recognizes standard conventional commit types:
- `feat`, `fix`, `docs`, `style`, `refactor`
- `test`, `chore`, `perf`, `ci`, `build`, `revert`

Example format:
```
type(scope): description

feat(auth): add OAuth2 integration
fix(api): handle null response correctly
docs(readme): update installation instructions
```

## Works Great With

### friendly-snippets
If you have `friendly-snippets` installed, you get the best of both worlds:
- **friendly-snippets** provides: `feat(): `, `fix(): `, etc. snippets to quickly start your commit
- **csc.nvim** provides: intelligent scope completion once you're inside the parentheses

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

## License

## TODOs:
- TODO: add license
- TODO: do versioning
- TODO: confirm installation instructions
- TODO: make it so this can be installed as a dependency of nvim-cmp
