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

# Marker definitions for managed configuration block
BEGIN_MARKER="# BEGIN shell-setup"
END_MARKER="# END shell-setup"
OLD_MARKER="# MANAGED BY shell-setup"

# Helper function to write managed configuration block
write_managed_config() {
    echo "$BEGIN_MARKER"
    cat "$SOURCE_KITTY"
    echo "$END_MARKER"
}

# Validate source file exists and has content
if [ ! -f "$SOURCE_KITTY" ]; then
    warn "Kitty config not found at $SOURCE_KITTY - skipping configuration"
elif [ ! -s "$SOURCE_KITTY" ]; then
    warn "Kitty config is empty at $SOURCE_KITTY - skipping configuration"
else
    # Create config directory if it doesn't exist
    mkdir -p "$KITTY_CONFIG_DIR"

    # Always create a backup before any modification (if file exists)
    if [ -f "$KITTY_CONFIG_FILE" ]; then
        BACKUP_FILE="${KITTY_CONFIG_FILE}.bak-$(date +%s)"
        if ! cp "$KITTY_CONFIG_FILE" "$BACKUP_FILE"; then
            warn "Failed to create backup - aborting to prevent data loss"
            exit 1
        fi
        info "Backed up existing Kitty config to $BACKUP_FILE"
    fi

    # Detect old single-marker format and migrate to new paired markers
    if [ -f "$KITTY_CONFIG_FILE" ] && grep -q "^$OLD_MARKER\$" "$KITTY_CONFIG_FILE" 2>/dev/null; then
        info "Migrating from old marker format to new paired markers..."
        # Non-destructive migration: replace only the old marker line with new paired markers
        TEMP_FILE=$(mktemp "${KITTY_CONFIG_FILE}.XXXXXX") || {
            warn "Failed to create temp file - aborting migration"
            exit 1
        }

        # Use awk to preserve all content, replacing only the old marker line
        awk -v old="$OLD_MARKER" -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v source="$SOURCE_KITTY" '
            $0 == old {
                print begin
                while ((getline line < source) > 0) print line
                close(source)
                print end
                next
            }
            { print }
        ' "$KITTY_CONFIG_FILE" > "$TEMP_FILE"

        if [ -s "$TEMP_FILE" ]; then
            mv "$TEMP_FILE" "$KITTY_CONFIG_FILE"
            success "Migrated to new marker format (preserved user customizations)"
        else
            rm -f "$TEMP_FILE"
            warn "Migration failed - config unchanged (backup exists at $BACKUP_FILE)"
        fi
    # Handle paired marker updates
    elif [ -f "$KITTY_CONFIG_FILE" ] && grep -q "^$BEGIN_MARKER\$" "$KITTY_CONFIG_FILE" 2>/dev/null; then
        # Validate marker integrity
        BEGIN_COUNT=$(grep -c "^$BEGIN_MARKER\$" "$KITTY_CONFIG_FILE" 2>/dev/null || echo "0")
        END_COUNT=$(grep -c "^$END_MARKER\$" "$KITTY_CONFIG_FILE" 2>/dev/null || echo "0")

        if [ "$BEGIN_COUNT" != "1" ] || [ "$END_COUNT" != "1" ]; then
            warn "Marker integrity issue detected (BEGIN: $BEGIN_COUNT, END: $END_COUNT)"
            warn "Replacing entire file with managed config (backup: $BACKUP_FILE)"
            write_managed_config > "$KITTY_CONFIG_FILE"
        else
            # Atomic update: build new file in temp, then replace
            TEMP_FILE=$(mktemp "${KITTY_CONFIG_FILE}.XXXXXX") || {
                warn "Failed to create temp file - aborting update"
                exit 1
            }

            # Use awk with exact string matching to extract and rebuild config
            awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
                # Print everything before BEGIN marker
                !found_begin && $0 != begin { print; next }
                # Mark that we found BEGIN and skip until END
                $0 == begin { found_begin=1; next }
                # Mark that we found END and start printing again
                $0 == end { found_end=1; next }
                # Print everything after END marker
                found_end { print }
            ' "$KITTY_CONFIG_FILE" > "$TEMP_FILE"

            # Insert managed configuration at the position where BEGIN was
            # First, get content before BEGIN
            TEMP_FILE2=$(mktemp "${KITTY_CONFIG_FILE}.XXXXXX") || {
                rm -f "$TEMP_FILE"
                warn "Failed to create second temp file - aborting update"
                exit 1
            }

            awk -v marker="$BEGIN_MARKER" '$0 == marker { exit } { print }' "$KITTY_CONFIG_FILE" > "$TEMP_FILE2"
            write_managed_config >> "$TEMP_FILE2"
            awk -v marker="$END_MARKER" 'found { print } $0 == marker { found=1 }' "$KITTY_CONFIG_FILE" >> "$TEMP_FILE2"

            # Verify temp file has content and markers, then perform atomic replacement
            if [ -s "$TEMP_FILE2" ] && grep -q "^$BEGIN_MARKER\$" "$TEMP_FILE2" && grep -q "^$END_MARKER\$" "$TEMP_FILE2"; then
                mv "$TEMP_FILE2" "$KITTY_CONFIG_FILE"
                rm -f "$TEMP_FILE"
                success "Updated managed configuration (preserved user customizations)"
            else
                rm -f "$TEMP_FILE" "$TEMP_FILE2"
                warn "Update failed - validation failed. Config unchanged (backup: $BACKUP_FILE)"
            fi
        fi
    else
        # First-time setup or file doesn't exist - create with markers
        write_managed_config > "$KITTY_CONFIG_FILE"
        success "Kitty configuration deployed with markers"
        info "You can add custom settings before BEGIN or after END markers"
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
info "Configuration management:"
echo "  • Config is managed between '# BEGIN shell-setup' and '# END shell-setup' markers"
echo "  • Add custom settings BEFORE the BEGIN marker or AFTER the END marker"
echo "  • Running this script again will update managed settings automatically"
echo "  • Your custom settings outside markers will be preserved"
echo
