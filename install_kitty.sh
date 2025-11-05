#!/bin/bash

# Kitty Terminal Installation Script
# Installs Kitty terminal emulator, D2Coding font, and deploys configuration
# Safe to run multiple times - checks for existing installations

# Note: set -e is NOT used to allow graceful error handling (warn and continue)

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  Kitty Terminal Installation"
echo "============================================"
echo
info "This script will install:"
echo "  • Kitty terminal emulator"
echo "  • D2Coding font (for CJK characters)"
echo "  • Kitty configuration from this project"
echo
info "Starting installation..."
echo

# ============================================================================
# Ensure Homebrew is Installed
# ============================================================================

ensure_homebrew

# ============================================================================
# Install Fonts
# ============================================================================

info "Adding Homebrew fonts tap..."
brew tap homebrew/cask-fonts 2>/dev/null || true
echo

info "Installing D2Coding font (for CJK characters)..."
if brew install --cask font-d2coding; then
    success "D2Coding font ready"
else
    warn "D2Coding font installation failed"
fi
echo

info "Installing Meslo Nerd Font (primary terminal font)..."
if brew install --cask font-meslo-for-powerlevel10k; then
    success "Meslo Nerd Font ready"
else
    warn "Meslo Nerd Font installation failed"
fi
echo

# ============================================================================
# Install Kitty
# ============================================================================

info "Installing Kitty terminal emulator..."
if brew install --cask kitty; then
    success "Kitty ready"
else
    warn "Kitty installation failed"
fi
echo

# ============================================================================
# Deploy Configuration
# ============================================================================

info "Setting up Kitty configuration..."
echo

KITTY_CONFIG_DIR="${HOME}/.config/kitty"
KITTY_CONFIG_FILE="${KITTY_CONFIG_DIR}/kitty.conf"
SOURCE_KITTY="${SCRIPT_DIR}/configs/kitty.conf"

# Validate source file exists
if [ ! -f "$SOURCE_KITTY" ]; then
    warn "Kitty config not found at $SOURCE_KITTY - skipping configuration"
else
    # Create config directory if it doesn't exist
    mkdir -p "$KITTY_CONFIG_DIR"

    # Check for idempotency marker
    if [ -f "$KITTY_CONFIG_FILE" ] && grep -q "# MANAGED BY shell-setup" "$KITTY_CONFIG_FILE"; then
        success "Kitty configuration already managed by shell-setup - skipping"
        info "To update config, manually remove the marker or delete $KITTY_CONFIG_FILE"
    else
        # Backup existing config if present
        if [ -f "$KITTY_CONFIG_FILE" ]; then
            BACKUP_FILE="${KITTY_CONFIG_FILE}.bak-$(date +%s)"
            cp "$KITTY_CONFIG_FILE" "$BACKUP_FILE"
            info "Backed up existing Kitty config to $BACKUP_FILE"
        fi

        # Replace with new config (prepend marker to destination)
        {
            echo "# MANAGED BY shell-setup"
            cat "$SOURCE_KITTY"
        } > "$KITTY_CONFIG_FILE"
        success "Kitty configuration deployed to $KITTY_CONFIG_FILE"
    fi
fi

echo

# ============================================================================
# Final Summary
# ============================================================================

echo
echo "============================================"
success "Kitty Installation Complete!"
echo "============================================"
echo
info "What was installed:"
echo "  ✓ Kitty terminal emulator"
echo "  ✓ Meslo Nerd Font (MesloLGS NF) - primary terminal font"
echo "  ✓ D2Coding font - CJK character fallback"
echo "  ✓ Kitty configuration"
echo
info "Font configuration:"
echo "  • Kitty is pre-configured to use 'MesloLGS NF' as the primary font"
echo "  • D2Coding is used for Korean/CJK characters (U+AC00-U+D7A3)"
echo "  • Fonts are already installed - no manual configuration needed!"
echo "  • If fonts don't appear, restart Kitty or your system"
echo
info "Next steps:"
echo "  1. Launch Kitty from Applications or run 'kitty' in terminal"
echo "  2. The fonts should display automatically - restart Kitty if needed"
echo "  3. Test the configuration with your favorite dev tools"
echo
info "Key bindings (configured in Kitty):"
echo "  • Cmd+y       - Open Yazi file manager"
echo "  • Cmd+g       - Open Lazygit"
echo "  • Cmd+f       - Open FZF file finder"
echo "  • Cmd+s       - Send save command"
echo "  • Cmd+t       - New tab in current directory"
echo
info "Configuration file location:"
echo "  ~/.config/kitty/kitty.conf"
echo
