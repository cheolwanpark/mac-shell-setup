#!/bin/bash

# macOS Development Environment Setup Script
# This script installs development tools and configures zsh with oh-my-zsh and powerlevel10k
# Safe to run multiple times - checks for existing installations

set -e

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  macOS Development Environment Setup"
echo "============================================"
echo
info "This script will install:"
echo "  • Homebrew (if not already installed)"
echo "  • Development tools (tmux, yazi, lazygit, helix, etc.)"
echo "  • Zsh with oh-my-zsh and powerlevel10k theme"
echo
info "Starting setup..."
echo

# ============================================================================
# Part 1: Homebrew & Development Tools
# ============================================================================

ensure_homebrew
info "Installing development tools..."
echo

# Core terminal tools
info "Installing tmux (terminal multiplexer)..."
if brew install tmux; then
    success "tmux ready"
else
    warn "tmux installation failed"
fi
echo

info "Installing yazi (modern file manager)..."
if brew install yazi; then
    success "yazi ready"
else
    warn "yazi installation failed"
fi
echo

info "Installing lazygit (git interface)..."
if brew install lazygit; then
    success "lazygit ready"
else
    warn "lazygit installation failed"
fi
echo

info "Installing helix (text editor)..."
if brew install helix; then
    success "helix ready"
else
    warn "helix installation failed"
fi
echo

# Utility tools
info "Installing utility tools (ffmpeg, 7zip, jq, poppler, bat)..."
if brew install ffmpeg sevenzip jq poppler bat; then
    success "Utility tools ready"
else
    warn "Some utilities failed to install - check output above"
fi
echo

info "Installing command-line tools (fd, ripgrep, fzf, zoxide)..."
if brew install fd ripgrep fzf zoxide; then
    success "CLI tools ready"
else
    warn "Some CLI tools failed to install - check output above"
fi

# Setup fzf shell integration (key bindings and completion)
if command -v fzf &>/dev/null; then
    info "Setting up fzf shell integration..."
    FZF_INSTALL_SCRIPT="$(brew --prefix)/opt/fzf/install"
    if [ -f "$FZF_INSTALL_SCRIPT" ]; then
        if "$FZF_INSTALL_SCRIPT" --key-bindings --completion --no-update-rc --all; then
            success "fzf shell integration configured"
        else
            warn "fzf shell integration setup failed"
            info "To set up manually, run: $FZF_INSTALL_SCRIPT --all"
        fi
    else
        warn "fzf install script not found at $FZF_INSTALL_SCRIPT"
        info "Shell integration skipped - you may need to configure manually"
    fi
else
    warn "fzf not found in PATH - skipping shell integration setup"
fi
echo

info "Installing image tools (resvg, imagemagick)..."
if brew install resvg imagemagick; then
    success "Image tools ready"
else
    warn "Image tools installation failed - check output above"
fi
echo

info "Adding Homebrew fonts tap..."
brew tap homebrew/cask-fonts 2>/dev/null || true

info "Installing Nerd Font for terminal icons..."
if brew install --cask font-symbols-only-nerd-font; then
    success "Nerd Font ready"
else
    warn "Font installation failed - check output above"
fi

echo
success "Development tools installation complete!"
echo

# ============================================================================
# Part 2: Zsh Setup
# ============================================================================

info "Starting zsh setup..."
echo

# --- Check Prerequisites ---
info "Checking prerequisites..."

if ! command -v git &>/dev/null; then
    error "Git is not installed. Please install it first"
fi
success "Git is installed"

if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
    error "Neither curl nor wget is installed. Please install one of them"
fi
success "curl/wget is available"

echo

# --- Install/Check Zsh ---
info "Checking zsh installation..."

ZSH_PATH=""
if [ -f /bin/zsh ]; then
    ZSH_PATH="/bin/zsh"
    success "System zsh found at $ZSH_PATH"
elif command -v zsh &>/dev/null; then
    ZSH_PATH="$(which zsh)"
    success "Zsh found at $ZSH_PATH"
else
    info "zsh not found. Installing via Homebrew..."
    if brew install zsh; then
        ZSH_PATH="$(which zsh)"
        success "Zsh installed at $ZSH_PATH"
    else
        error "Failed to install zsh via Homebrew"
    fi
fi

# Verify zsh version >= 5.1
ZSH_VERSION=$(zsh --version 2>&1 | awk '{print $2}')
# Compare versions: extract major.minor and check if >= 5.1
ZSH_MAJOR=$(echo "$ZSH_VERSION" | cut -d. -f1)
ZSH_MINOR=$(echo "$ZSH_VERSION" | cut -d. -f2)
if [ "$ZSH_MAJOR" -lt 5 ] || { [ "$ZSH_MAJOR" -eq 5 ] && [ "$ZSH_MINOR" -lt 1 ]; }; then
    error "Zsh version 5.1+ required, but found $ZSH_VERSION"
fi
success "Zsh version $ZSH_VERSION is compatible"

echo

# --- Install Oh-My-Zsh ---
info "Checking oh-my-zsh installation..."

OMZ_DIR="${HOME}/.oh-my-zsh"
if [ -d "$OMZ_DIR" ]; then
    success "Oh-my-zsh is already installed at $OMZ_DIR"
else
    info "Installing oh-my-zsh..."
    if sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc; then
        success "Oh-my-zsh installed successfully"
    else
        error "Failed to install oh-my-zsh"
    fi
fi

echo

# --- Install Powerlevel10k Theme ---
info "Checking powerlevel10k theme..."

P10K_DIR="${OMZ_DIR}/custom/themes/powerlevel10k"
if [ -d "$P10K_DIR" ]; then
    success "Powerlevel10k is already installed"
else
    info "Installing powerlevel10k theme..."
    if git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"; then
        success "Powerlevel10k theme installed successfully"
    else
        error "Failed to clone powerlevel10k repository"
    fi
fi

echo

# --- Configure .zshrc ---
info "Configuring .zshrc..."

ZSHRC="${HOME}/.zshrc"
if [ ! -f "$ZSHRC" ]; then
    error ".zshrc not found and oh-my-zsh should have created it. Something went wrong."
fi

# Backup .zshrc before making changes
ZSHRC_BACKUP="${ZSHRC}.backup.$(date +%s)"
cp "$ZSHRC" "$ZSHRC_BACKUP"
info "Backed up .zshrc to $ZSHRC_BACKUP"

# Update ZSH_THEME line
P10K_THEME="powerlevel10k/powerlevel10k"
if grep -q "^ZSH_THEME=" "$ZSHRC"; then
    # Replace existing theme line using temp file (portable across macOS/Linux)
    sed "s|^ZSH_THEME=.*|ZSH_THEME=\"${P10K_THEME}\"|" "$ZSHRC" > "$ZSHRC.tmp"
    mv "$ZSHRC.tmp" "$ZSHRC"
    success "Updated ZSH_THEME to powerlevel10k in .zshrc"
else
    # Add theme line at top of file
    {
        echo "ZSH_THEME=\"${P10K_THEME}\""
        cat "$ZSHRC"
    } > "$ZSHRC.tmp"
    mv "$ZSHRC.tmp" "$ZSHRC"
    success "Added ZSH_THEME=powerlevel10k to .zshrc"
fi

# Ensure .p10k.zsh is sourced
P10K_SOURCE_LINE='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
if ! grep -Fxq "$P10K_SOURCE_LINE" "$ZSHRC"; then
    echo "" >> "$ZSHRC"
    echo "# Powerlevel10k configuration" >> "$ZSHRC"
    echo "$P10K_SOURCE_LINE" >> "$ZSHRC"
    success "Added .p10k.zsh source line to .zshrc"
else
    success ".p10k.zsh is already sourced in .zshrc"
fi

echo

# --- Deploy Powerlevel10k Configuration ---
info "Setting up powerlevel10k configuration..."

PROJECT_P10K="${SCRIPT_DIR}/configs/.p10k.zsh"
USER_P10K="${HOME}/.p10k.zsh"

if [ ! -f "$PROJECT_P10K" ]; then
    warn "No .p10k.zsh found in configs/ directory"
    warn "Powerlevel10k will run its configuration wizard on first launch"
    warn "You can run 'p10k configure' anytime to customize the prompt"
else
    if [ -f "$USER_P10K" ]; then
        # User already has a config file - preserve it (don't overwrite)
        success "User's .p10k.zsh already exists - preserving existing configuration"
        info "If you want to use the project's config, manually run: cp '$PROJECT_P10K' '$USER_P10K'"
    else
        # First time setup - deploy config from project
        cp "$PROJECT_P10K" "$USER_P10K"
        success "Deployed .p10k.zsh configuration from project"
    fi
fi

echo

# --- Font Installation ---
info "Installing Meslo Nerd Font for powerlevel10k..."

info "Adding Homebrew fonts tap..."
brew tap homebrew/cask-fonts 2>/dev/null || true

if brew install --cask font-meslo-for-powerlevel10k; then
    success "Meslo Nerd Font installed"
else
    warn "Font installation failed - you may need to install it manually"
fi

echo
info "Font installed. Configure your terminal to use it:"
info "  - iTerm2/Terminal: Preferences → Profiles → Text → Font → MesloLGS NF"
info "  - VSCode: Settings → Terminal › Integrated: Font Family → 'MesloLGS NF'"
info "  - Kitty: Already configured if using configs/kitty.conf"
echo

# --- Shell Change Instructions ---
info "Checking default shell..."

# Get actual default shell from macOS (dscl), fallback to $SHELL environment variable
if command -v dscl &>/dev/null; then
    CURRENT_SHELL=$(dscl . -read ~/ UserShell 2>/dev/null | awk '{print $2}' || echo "$SHELL")
else
    CURRENT_SHELL="$SHELL"
fi

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    success "Default shell is already zsh"
else
    warn "Default shell is not zsh: $CURRENT_SHELL"
    echo
    echo "To make zsh your default shell, run:"
    echo "  chsh -s $ZSH_PATH"
    echo
    echo "You'll be prompted for your password. After changing the shell,"
    echo "log out and log back in for changes to take effect."
    echo
fi

# ============================================================================
# Part 3: Configuration Files & Scripts Deployment
# ============================================================================

echo
info "Deploying configuration files..."
echo

# --- Deploy Helix Configuration ---
info "Setting up Helix configuration..."

HELIX_CONFIG_DIR="${HOME}/.config/helix"
HELIX_CONFIG_FILE="${HELIX_CONFIG_DIR}/config.toml"
SOURCE_HELIX="${SCRIPT_DIR}/configs/helix.toml"

if [ -f "$SOURCE_HELIX" ]; then
    # Create config directory if it doesn't exist
    mkdir -p "$HELIX_CONFIG_DIR"

    # Backup existing config if present
    if [ -f "$HELIX_CONFIG_FILE" ]; then
        BACKUP_FILE="${HELIX_CONFIG_FILE}.bak-$(date +%s)"
        cp "$HELIX_CONFIG_FILE" "$BACKUP_FILE"
        info "Backed up existing Helix config to $BACKUP_FILE"
    fi

    # Copy new config
    cp "$SOURCE_HELIX" "$HELIX_CONFIG_FILE"
    success "Helix configuration deployed to $HELIX_CONFIG_FILE"
else
    warn "Helix config not found at $SOURCE_HELIX - skipping"
fi

echo

# --- Deploy Tmux Configuration ---
info "Setting up Tmux configuration..."

TMUX_CONFIG="${HOME}/.tmux.conf"
SOURCE_TMUX="${SCRIPT_DIR}/configs/tmux.conf"

if [ -f "$SOURCE_TMUX" ]; then
    # Backup existing config if present
    if [ -f "$TMUX_CONFIG" ]; then
        BACKUP_FILE="${TMUX_CONFIG}.bak-$(date +%s)"
        cp "$TMUX_CONFIG" "$BACKUP_FILE"
        info "Backed up existing Tmux config to $BACKUP_FILE"
    fi

    # Copy new config
    cp "$SOURCE_TMUX" "$TMUX_CONFIG"
    success "Tmux configuration deployed to $TMUX_CONFIG"
else
    warn "Tmux config not found at $SOURCE_TMUX - skipping"
fi

echo

# --- Deploy Zsh Profile (with markers for idempotency) ---
info "Setting up zsh profile..."

ZPROFILE="${HOME}/.zprofile"
SOURCE_ZPROFILE="${SCRIPT_DIR}/configs/zprofile"

if [ -f "$SOURCE_ZPROFILE" ]; then
    # Create .zprofile if it doesn't exist
    touch "$ZPROFILE"

    # Define markers
    BEGIN_MARKER="# BEGIN shell-setup"
    END_MARKER="# END shell-setup"

    # Check if our section already exists
    if grep -q "$BEGIN_MARKER" "$ZPROFILE"; then
        info "Updating existing shell-setup section in .zprofile..."
        # Remove old section (use awk for literal string matching)
        awk "/$BEGIN_MARKER/,/$END_MARKER/{next} 1" "$ZPROFILE" > "${ZPROFILE}.tmp"
        mv "${ZPROFILE}.tmp" "$ZPROFILE"
    else
        info "Adding shell-setup section to .zprofile..."
    fi

    # Append new section with markers
    {
        echo ""
        echo "$BEGIN_MARKER"
        cat "$SOURCE_ZPROFILE"
        echo "$END_MARKER"
    } >> "$ZPROFILE"

    success "Zsh profile updated at $ZPROFILE"
else
    warn "Zprofile config not found at $SOURCE_ZPROFILE - skipping"
fi

echo

# --- Deploy Scripts ---
info "Setting up scripts..."

SCRIPTS_DIR="${HOME}/scripts"
SOURCE_SCRIPTS="${SCRIPT_DIR}/scripts"

if [ -d "$SOURCE_SCRIPTS" ]; then
    # Create scripts directory if it doesn't exist
    mkdir -p "$SCRIPTS_DIR"

    # Check if there are any files to copy
    if [ -n "$(find "$SOURCE_SCRIPTS" -maxdepth 1 -type f 2>/dev/null)" ]; then
        # Copy scripts
        for script in "$SOURCE_SCRIPTS"/*; do
            if [ -f "$script" ]; then
                script_name=$(basename "$script")
                dest_path="$SCRIPTS_DIR/$script_name"

                # Backup if exists
                if [ -f "$dest_path" ]; then
                    BACKUP_FILE="${dest_path}.bak-$(date +%s)"
                    cp "$dest_path" "$BACKUP_FILE"
                    info "Backed up existing $script_name to $BACKUP_FILE"
                fi

                # Copy script
                cp "$script" "$dest_path"

                # Make executable if it has a shebang
                if head -n1 "$script" 2>/dev/null | grep -q '^#!'; then
                    chmod +x "$dest_path"
                fi

                success "Deployed script: $script_name"
            fi
        done

        info "Scripts are now available in ~/scripts"
        info "PATH will include ~/scripts after sourcing ~/.zprofile"
    else
        warn "No script files found in $SOURCE_SCRIPTS - skipping"
    fi
else
    warn "Scripts directory not found at $SOURCE_SCRIPTS - skipping"
fi

echo
success "Configuration deployment complete!"
echo

# ============================================================================
# Final Summary
# ============================================================================

echo
echo "============================================"
success "Setup complete!"
echo "============================================"
echo
info "What was set up:"
echo "  ✓ Homebrew and development tools"
echo "  ✓ Zsh with oh-my-zsh and powerlevel10k"
echo "  ✓ Meslo Nerd Font for terminal icons"
echo "  ✓ Helix, Tmux, and Zsh configurations"
echo "  ✓ Scripts deployed to ~/scripts"
echo
info "Additional setup scripts:"
echo "  • ./install_agents.sh  - Install AI coding assistants (Claude Code, Gemini CLI, Codex)"
echo "  • ./install_kitty.sh   - Install Kitty terminal with configuration"
echo
info "Next steps:"
echo "  1. Configure your terminal to use the Meslo Nerd Font (see instructions above)"
echo "  2. If you changed the default shell, log out and log back in"
echo "  3. Run 'source ~/.zprofile' to load PATH updates"
echo "  4. Run 'exec zsh' to start using zsh immediately"
echo "  5. (Optional) Run additional setup scripts as needed"
echo
info "Useful commands:"
echo "  • tm [name]    - Create/attach tmux session (try 'tm' or 'tm myproject')"
echo "  • tmux         - Start terminal multiplexer"
echo "  • yazi         - Launch file manager (Ctrl+y in tmux/helix)"
echo "  • lazygit      - Open git interface (Ctrl+g in tmux/helix)"
echo "  • hx           - Start helix editor"
echo "  • p10k configure - Customize your prompt"
echo
info "Key bindings:"
echo "  • Ctrl+y       - Open Yazi file manager (in tmux/helix)"
echo "  • Ctrl+g       - Open Lazygit (in tmux/helix)"
echo "  • Ctrl+s       - Save file (in helix)"
echo "  • Ctrl+r       - Reload tmux config (in tmux)"
echo
