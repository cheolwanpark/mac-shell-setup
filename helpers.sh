#!/bin/bash

# Shared helper functions for shell-setup scripts
# This file is sourced by setup.sh, install_agents.sh, and install_kitty.sh

# ============================================================================
# Message Display Functions
# ============================================================================

info() {
    echo "[INFO] $1"
}

warn() {
    echo "[WARN] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

success() {
    echo "[✓] $1"
}

# ============================================================================
# Homebrew Management
# ============================================================================

ensure_homebrew() {
    info "Checking Homebrew installation..."
    echo

    # Check if brew is already in PATH
    if command -v brew &>/dev/null; then
        success "Homebrew is already installed"
    # Check if Homebrew exists but not in PATH (Apple Silicon)
    elif [ -f "/opt/homebrew/bin/brew" ]; then
        info "Homebrew found at /opt/homebrew/bin/brew - adding to PATH"
        eval "$(/opt/homebrew/bin/brew shellenv)"
        success "Homebrew is now available"
    # Check if Homebrew exists but not in PATH (Intel Mac)
    elif [ -f "/usr/local/bin/brew" ]; then
        info "Homebrew found at /usr/local/bin/brew - adding to PATH"
        eval "$(/usr/local/bin/brew shellenv)"
        success "Homebrew is now available"
    # Homebrew not found - install it
    else
        info "Homebrew not found. Installing Homebrew..."
        info "You may be prompted for your password"
        echo

        if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            # Add Homebrew to PATH for this script session
            if [ -f "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
            elif [ -f "/usr/local/bin/brew" ]; then
                eval "$(/usr/local/bin/brew shellenv)"
            fi
            success "Homebrew installed successfully"
        else
            error "Failed to install Homebrew. Please install it manually from https://brew.sh/"
        fi
    fi
    echo
}
