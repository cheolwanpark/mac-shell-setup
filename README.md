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

# 2. AI coding agents (optional) - installs Claude Code, Gemini CLI, Codex
./install_agents.sh

# 3. Kitty terminal (optional, desktop only - NOT for servers)
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

### AI Agents (install_agents.sh)

- **Claude Code** - Anthropic's AI coding assistant
- **Gemini CLI** - Google's AI CLI tool
- **Codex** - AI development tool

### Kitty Terminal (install_kitty.sh)

- **Kitty** - GPU-accelerated terminal emulator
- **Fonts** - MesloLGS NF (nerd font), D2Coding (CJK support)

## Key Shortcuts

### Tmux
- **Ctrl+y** - Open Yazi file manager
- **Ctrl+g** - Open Lazygit
- **Ctrl+f** - Open FZF file search
- **Ctrl+r** - Reload config

### Kitty (if installed)
- **Cmd+y** - Open Yazi
- **Cmd+g** - Open Lazygit
- **Cmd+f** - Open FZF search
- **Cmd+s** - Save
- **Cmd+t** - New tab in current directory

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
