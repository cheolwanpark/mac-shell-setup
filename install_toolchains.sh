#!/bin/bash

# Helix Language Toolchains Installation Script
# This script installs package managers for language servers:
#   • uv (Python package manager)
#   • nvm (Node.js version manager)
#   • rustup (Rust toolchain installer)
#
# Run this script first, then restart your shell, then run install_language_servers.sh

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  Helix Language Toolchains Setup"
echo "============================================"
echo
info "This script will install package managers needed for language servers:"
echo "  • uv      - Python package installer (for ruff)"
echo "  • nvm     - Node.js version manager (for pyright, TypeScript, JSON, Docker LSPs)"
echo "  • rustup  - Rust toolchain (for rust-analyzer, taplo)"
echo
info "After installation, you'll need to restart your shell."
echo

# ============================================================================
# Install uv (Python Package Manager)
# ============================================================================

info "Checking uv (Python package manager)..."
echo

if command -v uv &>/dev/null; then
    UV_VERSION=$(uv --version 2>&1 || echo "unknown")
    success "uv is already installed: $UV_VERSION"
else
    echo "uv is a fast Python package installer and resolver."
    echo "It will be used to install: ruff"
    echo
    read -p "Install uv? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing uv..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            success "uv installed successfully"

            # uv installs to ~/.local/bin by default
            UV_BIN="$HOME/.local/bin"

            # Check if ~/.local/bin is in PATH via .zprofile
            ZPROFILE="${HOME}/.zprofile"
            touch "$ZPROFILE"

            if ! grep -q "/.local/bin" "$ZPROFILE"; then
                info "Adding $UV_BIN to PATH in .zprofile..."
                echo "" >> "$ZPROFILE"
                echo "# uv (Python package manager)" >> "$ZPROFILE"
                echo "export PATH=\"\$HOME/.local/bin:\$PATH\"" >> "$ZPROFILE"
                success "PATH updated in .zprofile"
            else
                info "~/.local/bin already in PATH"
            fi
        else
            warn "uv installation failed - you can install it manually later"
            info "Visit: https://docs.astral.sh/uv/getting-started/installation/"
        fi
    else
        warn "Skipping uv installation"
        warn "Without uv, Python tools (ruff) won't be installed"
    fi
fi

echo

# ============================================================================
# Install nvm (Node.js Version Manager)
# ============================================================================

info "Checking nvm (Node.js version manager)..."
echo

if [ -s "$HOME/.nvm/nvm.sh" ]; then
    # Source nvm to check version
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    NVM_VERSION=$(nvm --version 2>&1 || echo "unknown")
    success "nvm is already installed: v$NVM_VERSION"
else
    echo "nvm manages Node.js versions and allows installing npm packages."
    echo "It will be used to install: pyright, typescript-language-server,"
    echo "                            vscode-json-language-server, dockerfile-language-server"
    echo
    read -p "Install nvm? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing nvm..."
        NVM_VERSION="v0.39.7"
        if curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash; then
            success "nvm installed successfully"
            success "nvm will be available after shell restart"
        else
            warn "nvm installation failed - you can install it manually later"
            info "Visit: https://github.com/nvm-sh/nvm#installing-and-updating"
        fi
    else
        warn "Skipping nvm installation"
        warn "Without nvm, Node.js tools (pyright, TypeScript, JSON, Docker LSPs) won't be installed"
    fi
fi

echo

# ============================================================================
# Install rustup (Rust Toolchain)
# ============================================================================

info "Checking rustup (Rust toolchain)..."
echo

if command -v rustup &>/dev/null; then
    RUSTUP_VERSION=$(rustup --version 2>&1 | head -n1)
    success "rustup is already installed: $RUSTUP_VERSION"
else
    echo "rustup manages Rust toolchains and components."
    echo "It will be used to install: rust-analyzer, taplo"
    echo
    read -p "Install rustup? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Installing rustup..."
        if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
            success "rustup installed successfully"

            # rustup installs to ~/.cargo/bin and creates ~/.cargo/env
            CARGO_ENV="$HOME/.cargo/env"
            if [ -f "$CARGO_ENV" ]; then
                # Ensure cargo env is sourced in .zprofile
                ZPROFILE="${HOME}/.zprofile"
                touch "$ZPROFILE"

                # Define markers for idempotent updates
                BEGIN_MARKER="# BEGIN mac-shell-setup: cargo"
                END_MARKER="# END mac-shell-setup: cargo"

                # Check if our section already exists
                if grep -q "$BEGIN_MARKER" "$ZPROFILE"; then
                    info "Updating existing cargo section in .zprofile..."
                    # Remove old section
                    awk "/$BEGIN_MARKER/,/$END_MARKER/{next} 1" "$ZPROFILE" > "${ZPROFILE}.tmp"
                    mv "${ZPROFILE}.tmp" "$ZPROFILE"
                else
                    info "Adding cargo environment to .zprofile..."
                fi

                # Append new section with markers
                {
                    echo ""
                    echo "$BEGIN_MARKER"
                    echo ". \"\$HOME/.cargo/env\""
                    echo "$END_MARKER"
                } >> "$ZPROFILE"

                success "Cargo environment added to .zprofile"
                success "Cargo environment will be available after shell restart"
            fi
        else
            warn "rustup installation failed - you can install it manually later"
            info "Visit: https://rustup.rs/"
        fi
    else
        warn "Skipping rustup installation"
        warn "Without rustup, Rust tools (rust-analyzer, taplo) won't be installed"
    fi
fi

echo

# ============================================================================
# Summary
# ============================================================================

echo "============================================"
success "Toolchain installation complete!"
echo "============================================"
echo
info "What was installed:"

# Check what's installed
INSTALLED_COUNT=0
MISSING_COUNT=0

if command -v uv &>/dev/null || [ -x "$HOME/.local/bin/uv" ]; then
    echo "  ✓ uv      - Python package manager"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
else
    echo "  ✗ uv      - Not installed"
    MISSING_COUNT=$((MISSING_COUNT + 1))
fi

if [ -s "$HOME/.nvm/nvm.sh" ]; then
    echo "  ✓ nvm     - Node.js version manager"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
else
    echo "  ✗ nvm     - Not installed"
    MISSING_COUNT=$((MISSING_COUNT + 1))
fi

if command -v rustup &>/dev/null || [ -x "$HOME/.cargo/bin/rustup" ]; then
    echo "  ✓ rustup  - Rust toolchain"
    INSTALLED_COUNT=$((INSTALLED_COUNT + 1))
else
    echo "  ✗ rustup  - Not installed"
    MISSING_COUNT=$((MISSING_COUNT + 1))
fi

echo
info "Summary: $INSTALLED_COUNT installed, $MISSING_COUNT skipped"
echo

# ============================================================================
# Next Steps
# ============================================================================

echo "============================================"
info "Next steps:"
echo "============================================"
echo
if [ $INSTALLED_COUNT -gt 0 ]; then
    echo "1. Restart your shell to apply PATH changes:"
    echo "   exec zsh"
    echo
    echo "2. Run the language server installation script:"
    echo "   ./install_language_servers.sh"
    echo
else
    warn "No toolchains were installed."
    echo "You can run this script again to install them, or install manually:"
    echo "  • uv:     https://docs.astral.sh/uv/"
    echo "  • nvm:    https://github.com/nvm-sh/nvm"
    echo "  • rustup: https://rustup.rs/"
    echo
fi

echo "For reference, you can also use the combined script:"
echo "  ./install_languages.sh"
echo
