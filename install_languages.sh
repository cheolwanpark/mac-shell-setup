#!/bin/bash

# Helix Language Support - Combined Installation Script
# This script runs both toolchain and language server installation in sequence.
#
# It will:
# 1. Install toolchains (uv, nvm, rustup) with user prompts
# 2. Restart the shell environment
# 3. Install language servers using those toolchains
# 4. Deploy Helix configuration
#
# Alternatively, you can run the scripts separately:
#   ./install_toolchains.sh
#   exec zsh
#   ./install_language_servers.sh

set -e

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  Helix Language Support - Full Setup"
echo "============================================"
echo
info "This combined script will:"
echo "  1. Install toolchains (uv, nvm, rustup)"
echo "  2. Restart the shell environment"
echo "  3. Install language servers"
echo "  4. Deploy Helix configuration"
echo
info "Alternatively, run scripts separately for more control:"
echo "  • ./install_toolchains.sh"
echo "  • exec zsh"
echo "  • ./install_language_servers.sh"
echo
read -p "Continue with combined installation? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Installation cancelled"
    exit 0
fi
echo

# ============================================================================
# Phase 1: Install Toolchains
# ============================================================================

info "Phase 1: Installing toolchains..."
echo

if [ -f "${SCRIPT_DIR}/install_toolchains.sh" ]; then
    bash "${SCRIPT_DIR}/install_toolchains.sh"

    if [ $? -ne 0 ]; then
        error "Toolchain installation failed"
        exit 1
    fi
else
    error "install_toolchains.sh not found in $SCRIPT_DIR"
    exit 1
fi

echo
success "Phase 1 complete!"
echo

# ============================================================================
# Phase 2: Reload Environment and Install Language Servers
# ============================================================================

info "Phase 2: Installing language servers..."
echo
info "Restarting shell environment to load toolchains..."
echo

# Check if install_language_servers.sh exists
if [ ! -f "${SCRIPT_DIR}/install_language_servers.sh" ]; then
    error "install_language_servers.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Execute the language servers script in a new login shell with proper environment
# This ensures that the toolchains installed in Phase 1 are available via updated PATH
USER_SHELL=$(basename "$SHELL")

if [ "$USER_SHELL" = "zsh" ]; then
    # Running zsh - use login shell to source .zprofile
    exec zsh -l "${SCRIPT_DIR}/install_language_servers.sh"
elif [ "$USER_SHELL" = "bash" ]; then
    # Running bash - use login shell to source .bash_profile
    exec bash -l "${SCRIPT_DIR}/install_language_servers.sh"
else
    # Fallback: try to run directly
    exec "${SCRIPT_DIR}/install_language_servers.sh"
fi

# Note: exec replaces the current process, so code after this won't run
# The install_language_servers.sh script will print its own completion message
