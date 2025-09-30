# Contributing to csc.nvim

Thanks for your interest in contributing! PRs and suggestions are welcome.

## Reporting Issues

Please include:
- Neovim version (`:version`)
- Minimal config to reproduce the issue
- Error messages from `:CSC status` or `:messages`
- Your git version (`git --version`)

## Submitting Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes following conventional commits (`feat:`, `fix:`, etc.)
4. Push to your branch
5. Open a Pull Request

## Development Setup

Clone the repo and point your plugin manager to your local copy for testing changes.

Enable debug mode for development:
```lua
require('csc').setup({ debug = true })
```

## Code Style

- Use tabs for indentation as per lua_ls
- Follow existing patterns in the codebase
- Keep functions focused
- Add comments for complex logic

## Testing Your Changes

Run the built-in test commands to verify functionality:
- `:CSC test` - Test plugin functionality
- `:CSC test_git` - Test git integration
- `:CSC analyze` - Verify scope parsing
- Check `:messages` for debug output

## Questions?

Feel free to open an issue for discussion before implementing major changes.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
