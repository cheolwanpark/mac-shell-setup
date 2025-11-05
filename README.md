# Shell Setup for macOS

Automated development environment setup with modern CLI tools and integrated workflows.

## Prerequisites

- macOS (Intel or Apple Silicon)
- No prerequisites needed - the setup script will install everything including Xcode Command Line Tools and Rosetta 2 (Apple Silicon only)

## Installation

```bash
git clone https://github.com/YOUR-USERNAME/shell-setup.git
cd shell-setup

# 1. Core setup (required) - installs dev tools and shell environment
./setup.sh

# 2. Language servers (optional) - adds IDE features to Helix
./install_languages.sh

# 3. AI coding agents (optional) - installs Claude Code, Gemini CLI, Codex
./install_agents.sh

# 4. Kitty terminal (optional, desktop only - NOT for servers)
./install_kitty.sh

# Restart your shell
exec zsh
```

## What Gets Installed

### Core Tools (setup.sh)

**Essential Prerequisites:**
- **Xcode Command Line Tools** - Compilers (gcc, clang), build tools, and Git
- **Rosetta 2** - Intel app compatibility layer (Apple Silicon Macs only)
- **Homebrew** - Package manager for macOS

**Terminal & Shell:**
- **tmux** - Terminal multiplexer for managing sessions
- **oh-my-zsh** - Zsh framework
- **powerlevel10k** - Enhanced shell prompt theme

**Development Tools:**
- **helix** - Modern modal text editor
- **yazi** - Terminal file manager with image preview
- **lazygit** - Interactive Git interface

**CLI Utilities:**
- **fzf** - Fuzzy finder
- **zoxide** - Smarter cd command
- **ripgrep** - Fast grep alternative
- **fd** - User-friendly find alternative
- **bat** - Cat clone with syntax highlighting
- **jq** - JSON processor

**Other:** ffmpeg, 7zip, imagemagick, poppler, resvg

**Helper Scripts:**
- **tm** - Tmux session manager (`tm` or `tm <session-name>`)

### Language Servers (install_languages.sh)

Adds IDE-like features to Helix editor including autocomplete, diagnostics, go-to-definition, and type hints.

**Toolchains:**
- **uv** - Python package manager
- **nvm** - Node.js version manager
- **rustup** - Rust toolchain installer

**Language Servers by Language:**
- **Rust** - rust-analyzer (code completion, type hints, inline diagnostics)
- **Python** - ruff (fast linter/formatter), pyright (type checking)
- **TypeScript/JavaScript** - typescript-language-server (IntelliSense, refactoring)
- **C/C++** - clangd (code navigation, compile diagnostics)
- **Markdown** - marksman (link checking, document outline)
- **JSON** - vscode-json-language-server (schema validation)
- **Docker** - dockerfile-language-server (linting, auto-completion)
- **TOML** - taplo (formatting, validation)

### AI Agents (install_agents.sh)

- **Claude Code** - Anthropic's AI coding assistant
- **Gemini CLI** - Google's AI CLI tool
- **Codex** - AI development tool

### Kitty Terminal (install_kitty.sh)

- **Kitty** - GPU-accelerated terminal emulator
- **Fonts** - MesloLGS NF (nerd font), D2Coding (CJK support)
- **Theme** - [Ashen theme](https://github.com/helix-editor/helix/wiki/Themes#ashen) for both Helix and Kitty

## Key Shortcuts

### Tmux
**Prefix**: `Ctrl+a` (instead of default `Ctrl+b`)

To use any tmux command, press `Ctrl+a` first, then the key:
- **Prefix+y** (Ctrl+a then y) - Open Yazi file manager
- **Prefix+g** (Ctrl+a then g) - Open Lazygit
- **Prefix+f** (Ctrl+a then f) - Open FZF file search
- **Prefix+t** (Ctrl+a then t) - Open popup shell
- **Prefix+?** (Ctrl+a then ?) - Show shortcuts reference
- **Prefix+\\** (Ctrl+a then \\) - Vertical split (top-bottom)
- **Prefix+-** (Ctrl+a then -) - Horizontal split (side-by-side)
- **Prefix+r** (Ctrl+a then r) - Reload config

**Note**: Window splits replace default `%` and `"` bindings. To send a literal `Ctrl+a` to the shell (e.g., to move cursor to beginning of line), press `Ctrl+a` twice (i.e., `Ctrl+a Ctrl+a`).

### Kitty (if installed)
Kitty is configured to pass tmux prefix shortcuts seamlessly:
- **Cmd+a** - Sends tmux prefix (Ctrl+a) to tmux
- **Cmd+t** - New tab in current directory

To use tmux commands in Kitty, press **Cmd+a** first (sends the prefix), then press the command key:
- **Cmd+a, then y** - Open Yazi
- **Cmd+a, then g** - Open Lazygit
- **Cmd+a, then f** - Open FZF search
- **Cmd+a, then t** - Open popup shell

### Helix
- **Ctrl+y** - Open Yazi
- **Ctrl+g** - Open Lazygit
- **Ctrl+s** - Save buffer
- **Alt+,** / **Alt+.** - Previous/next buffer
- **Alt+w** - Close buffer

## After Installation

- Restart your terminal or run `exec zsh`
- Configuration files modified: `~/.zshrc`, `~/.zprofile`, `~/.tmux.conf`, `~/.config/helix/`, `~/.config/kitty/`
- Backups are created automatically before modifications
- Run `p10k configure` to customize your prompt
