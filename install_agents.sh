#!/bin/bash

# AI Coding Agents Installation Script
# Installs Claude Code, Gemini CLI, and Codex
# Safe to run multiple times - checks for existing installations

# Note: set -e is NOT used to allow graceful error handling (warn and continue)

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  AI Coding Agents Installation"
echo "============================================"
echo
info "This script will install:"
echo "  • Claude Code (AI coding assistant)"
echo "  • Gemini CLI (Google's AI command-line tool)"
echo "  • Codex (AI development tool)"
echo
info "Starting installation..."
echo

# ============================================================================
# Ensure Homebrew is Installed
# ============================================================================

ensure_homebrew

# ============================================================================
# Install AI Agents
# ============================================================================

info "Installing AI coding agents..."
echo

# Claude Code
info "Installing Claude Code..."
if brew install --cask claude-code; then
    success "Claude Code ready"
else
    warn "Claude Code installation failed"
fi
echo

# Gemini CLI
info "Installing Gemini CLI..."
if brew install gemini-cli; then
    success "Gemini CLI ready"
else
    warn "Gemini CLI installation failed"
fi
echo

# Codex
info "Installing Codex..."
if brew install --cask codex; then
    success "Codex ready"
else
    warn "Codex installation failed"
fi
echo

# ============================================================================
# Final Summary
# ============================================================================

echo
echo "============================================"
success "AI Agents Installation Complete!"
echo "============================================"
echo
info "What was installed:"
echo "  ✓ Claude Code - AI coding assistant"
echo "  ✓ Gemini CLI - Google's AI command-line tool"
echo "  ✓ Codex - AI development tool"
echo
info "Next steps:"
echo "  • Configure any required API keys for the agents"
echo "  • Check individual tool documentation for usage"
echo "  • Run 'claude-code --help', 'gemini-cli --help', etc. for commands"
echo
