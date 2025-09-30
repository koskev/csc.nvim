# csc.nvim

Commit Scope Completer - intelligent scope suggestions for conventional commits in Neovim.

![Demo](./csc-demo.gif?v=3)

## Why csc.nvim?

**The Problem:** When writing conventional commits, you need consistency in your scope names. Did you use `auth` or `authentication`? Was it `ui` or `frontend`? Without consistency, your git history becomes fragmented and less useful.

**Existing Solutions Fall Short:** While there are scope completions available (like those in commitizen or @commitlint), they require Node.js dependencies and project-specific configuration files. You shouldn't need to install a JavaScript toolchain just to get smart completions for your commit messages!

**The csc.nvim Difference:** 
- **Zero config, zero dependencies** (beyond nvim-cmp)
- **Learns from YOUR repository** - no generic scope lists
- **Pure Lua** - no Node.js, no package.json, no .commitlintrc
- **Intelligent ranking** - suggests your most-used scopes first
- **Lightning fast** - caches results, no performance impact

Unlike JavaScript-based solutions that require polluting your project with config files and node_modules, csc.nvim lives entirely in your editor, learning from your actual commit history.

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

Using lazy.nvim

```lua
{
  'yus-works/csc.nvim',
  dependencies = { 'hrsh7th/nvim-cmp' },
  ft = "gitcommit" -- recommended: only load in commit buffer
}
```

Using packer.nvim

```lua
use {
  'yus-works/csc.nvim',
  requires = { 'hrsh7th/nvim-cmp' },
  ft = { 'gitcommit' }, -- recommended: only load in commit buffer
}
```

Using vim-plug
```
Plug 'hrsh7th/nvim-cmp'
Plug 'yus-works/csc.nvim'
```

## Usage

The plugin automatically activates when editing git commit messages. Start typing a conventional commit and get scope suggestions:

```
feat(|): add new feature
     ^ cursor here triggers scope suggestions
```

## Works Great With

### friendly-snippets
If you have `friendly-snippets` installed, you get the best of both worlds:
- **friendly-snippets** provides: `feat(): `, `fix(): `, etc. snippets to quickly start your commit
- **csc.nvim** provides: intelligent scope completion once you're inside the parentheses

## Configuration

```lua
require('csc').setup({
  debug = false,  -- enables printing debug messages
  max_suggestions = 10,
})
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

## License

[MIT](LICENSE)
