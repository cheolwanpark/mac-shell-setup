#!/bin/bash

# Helix Language Servers Installation Script
# This script installs language servers for Helix editor.
#
# Prerequisites: uv, nvm, rustup must be installed first
# Run install_toolchains.sh first if you haven't already.

# Determine script directory and source helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/helpers.sh"

# ============================================================================
# Welcome
# ============================================================================

echo "============================================"
echo "  Helix Language Servers Installation"
echo "============================================"
echo
info "This script will install language servers for:"
echo "  • Rust        - rust-analyzer"
echo "  • Python      - ruff, pyright"
echo "  • TypeScript  - typescript-language-server"
echo "  • JavaScript  - typescript-language-server"
echo "  • C/C++       - clangd"
echo "  • Markdown    - marksman"
echo "  • JSON        - vscode-json-language-server"
echo "  • Docker      - dockerfile-language-server-nodejs"
echo "  • TOML        - taplo"
echo

# ============================================================================
# Prerequisites Check
# ============================================================================

info "Checking prerequisites..."
echo

PREREQUISITES_OK=true

# Check uv
if command -v uv &>/dev/null; then
    UV_VERSION=$(uv --version 2>&1)
    success "uv found: $UV_VERSION"
else
    warn "uv not found"
    echo "Please install uv first by running: ./install_toolchains.sh"
    PREREQUISITES_OK=false
fi

# Check nvm
if [ -s "$HOME/.nvm/nvm.sh" ]; then
    success "nvm found"
else
    warn "nvm not found"
    echo "Please install nvm first by running: ./install_toolchains.sh"
    PREREQUISITES_OK=false
fi

# Check rustup
if command -v rustup &>/dev/null; then
    RUSTUP_VERSION=$(rustup --version 2>&1 | head -n1)
    success "rustup found: $RUSTUP_VERSION"
else
    warn "rustup not found"
    echo "Please install rustup first by running: ./install_toolchains.sh"
    PREREQUISITES_OK=false
fi

# Exit if prerequisites not met
if [ "$PREREQUISITES_OK" = false ]; then
    echo
    echo "[ERROR] Prerequisites not met. Run ./install_toolchains.sh first." >&2
    exit 1
fi

echo
success "All prerequisites satisfied!"
echo

# ============================================================================
# Load Toolchain Environments
# ============================================================================

info "Loading toolchain environments..."
echo

# Load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Ensure Node LTS is installed
# Check if any version of Node is installed
if [ -z "$(nvm list --no-alias | grep 'v')" ]; then
    info "Installing Node.js LTS via nvm..."
    nvm install --lts
else
    info "Node.js already installed"
fi

# Use the installed LTS version
nvm use --lts >/dev/null 2>&1 || nvm use node >/dev/null 2>&1

NODE_VERSION=$(node --version 2>&1)
NPM_VERSION=$(npm --version 2>&1)
success "Node.js $NODE_VERSION, npm $NPM_VERSION"

# Load cargo
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

CARGO_VERSION=$(cargo --version 2>&1)
success "cargo $CARGO_VERSION"

echo

# ============================================================================
# Language Server Installation
# ============================================================================

info "Installing language servers..."
echo

# Track installation results
INSTALLED=()
SKIPPED=()
FAILED=()

# Helper function to check and install
install_tool() {
    local tool_name="$1"
    local check_command="$2"
    local install_command="$3"
    local description="$4"

    info "Checking $tool_name ($description)..."

    if command -v "$check_command" &>/dev/null; then
        success "$tool_name already installed"
        SKIPPED+=("$tool_name")
    else
        info "Installing $tool_name..."
        if eval "$install_command"; then
            success "$tool_name installed successfully"
            INSTALLED+=("$tool_name")
        else
            warn "$tool_name installation failed"
            FAILED+=("$tool_name")
        fi
    fi
    echo
}

# ============================================================================
# Python Language Servers (via uv)
# ============================================================================

info "Installing Python language servers via uv..."
echo

install_tool "ruff" "ruff" "uv tool install ruff" "Python linter and formatter"

# ============================================================================
# Node.js Language Servers (via npm)
# ============================================================================

info "Installing Node.js language servers via npm..."
echo

install_tool "pyright" "pyright" "npm install -g pyright" "Python type checker"

install_tool "typescript-language-server" "typescript-language-server" \
    "npm install -g typescript typescript-language-server" "TypeScript/JavaScript LSP"

install_tool "vscode-json-language-server" "vscode-json-language-server" \
    "npm install -g vscode-langservers-extracted" "JSON LSP"

install_tool "docker-langserver" "docker-langserver" \
    "npm install -g dockerfile-language-server-nodejs" "Docker LSP"

# ============================================================================
# Rust Language Servers (via rustup/cargo)
# ============================================================================

info "Installing Rust language servers via rustup/cargo..."
echo

# rust-analyzer (rustup component)
info "Checking rust-analyzer..."
if rustup component list --installed | grep -q "rust-analyzer"; then
    success "rust-analyzer already installed"
    SKIPPED+=("rust-analyzer")
else
    info "Installing rust-analyzer via rustup..."
    if rustup component add rust-analyzer; then
        success "rust-analyzer installed successfully"
        INSTALLED+=("rust-analyzer")
    else
        warn "rust-analyzer installation failed"
        FAILED+=("rust-analyzer")
    fi
fi
echo

# taplo (cargo install)
install_tool "taplo" "taplo" "cargo install taplo-cli --locked --features lsp" "TOML LSP"

# ============================================================================
# System Language Servers (via Homebrew/System)
# ============================================================================

info "Installing system language servers..."
echo

# clangd (from Xcode CLT or Homebrew)
info "Checking clangd (C/C++ LSP)..."
if command -v clangd &>/dev/null; then
    CLANGD_VERSION=$(clangd --version 2>&1 | head -n1)
    success "clangd already available: $CLANGD_VERSION"
    SKIPPED+=("clangd")
else
    if xcode-select -p &>/dev/null; then
        warn "clangd not found despite Xcode Command Line Tools being installed"
        info "Attempting to install via Homebrew (LLVM)..."
        if brew install llvm; then
            success "LLVM (includes clangd) installed"
            info "Note: You may need to add $(brew --prefix llvm)/bin to your PATH"
            INSTALLED+=("clangd")
        else
            warn "clangd installation failed"
            FAILED+=("clangd")
        fi
    else
        warn "Xcode Command Line Tools not found"
        info "Install with: xcode-select --install"
        FAILED+=("clangd")
    fi
fi
echo

# marksman (Homebrew)
install_tool "marksman" "marksman" "brew install marksman" "Markdown LSP"

# ============================================================================
# Configuration Deployment
# ============================================================================

info "Deploying Helix configuration..."
echo

HELIX_CONFIG_DIR="$HOME/.config/helix"
HELIX_LANGUAGES_TOML="$HELIX_CONFIG_DIR/languages.toml"
SOURCE_LANGUAGES_TOML="$SCRIPT_DIR/configs/languages.toml"

# Create config directory if it doesn't exist
mkdir -p "$HELIX_CONFIG_DIR"

# Check if source file exists
if [ ! -f "$SOURCE_LANGUAGES_TOML" ]; then
    warn "Source configuration not found at $SOURCE_LANGUAGES_TOML"
    warn "Skipping configuration deployment"
else
    # Backup existing config if present
    if [ -f "$HELIX_LANGUAGES_TOML" ]; then
        BACKUP_FILE="${HELIX_LANGUAGES_TOML}.backup-$(date +%s)"
        cp "$HELIX_LANGUAGES_TOML" "$BACKUP_FILE"
        info "Backed up existing config to $BACKUP_FILE"
    fi

    # Copy new config
    cp "$SOURCE_LANGUAGES_TOML" "$HELIX_LANGUAGES_TOML"
    success "Configuration deployed to $HELIX_LANGUAGES_TOML"
fi

echo

# ============================================================================
# Verification
# ============================================================================

info "Verifying language server installations..."
echo

# Helper function to check binary
check_binary() {
    local binary="$1"
    local name="${2:-$1}"

    if command -v "$binary" &>/dev/null; then
        local version=$("$binary" --version 2>&1 | head -n1 || echo "unknown")
        echo "  ✓ $name: $version"
        return 0
    else
        echo "  ✗ $name: NOT FOUND"
        return 1
    fi
}

VERIFIED=0
MISSING=0

check_binary "rust-analyzer" "rust-analyzer" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "ruff" "ruff" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "pyright" "pyright" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "typescript-language-server" "typescript-language-server" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "clangd" "clangd" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "marksman" "marksman" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "vscode-json-language-server" "vscode-json-language-server" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "docker-langserver" "docker-langserver" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))
check_binary "taplo" "taplo" && VERIFIED=$((VERIFIED + 1)) || MISSING=$((MISSING + 1))

echo

# ============================================================================
# Summary
# ============================================================================

echo "============================================"
success "Installation complete!"
echo "============================================"
echo
info "Summary:"
echo "  ✓ Installed:  ${#INSTALLED[@]} language server(s)"
echo "  ⊘ Skipped:    ${#SKIPPED[@]} (already installed)"
echo "  ✗ Failed:     ${#FAILED[@]}"
echo

if [ ${#FAILED[@]} -gt 0 ]; then
    warn "Failed installations:"
    for tool in "${FAILED[@]}"; do
        echo "  • $tool"
    done
    echo
    info "Troubleshooting:"
    echo "  • For clangd: Install Xcode Command Line Tools with 'xcode-select --install'"
    echo "  • For npm packages: Ensure Node.js is available with 'node --version'"
    echo "  • For cargo packages: Ensure Rust is available with 'cargo --version'"
    echo "  • Check logs above for specific error messages"
    echo
fi

echo "Verification: $VERIFIED found, $MISSING missing"
echo

# ============================================================================
# Next Steps
# ============================================================================

echo "============================================"
info "Next steps:"
echo "============================================"
echo
echo "1. Verify language servers are working:"
echo "   hx --health rust python typescript c json"
echo
echo "2. Test by opening a file:"
echo "   hx test.py"
echo
echo "3. (Optional) Add auto-format to ~/.config/helix/config.toml:"
echo "   [editor]"
echo "   auto-format = true"
echo
echo "4. (Optional) Configure specific formatters in config.toml as needed"
echo

info "For more information, see:"
echo "  • Helix documentation: https://docs.helix-editor.com/"
echo "  • Language configuration: $HELIX_LANGUAGES_TOML"
echo
