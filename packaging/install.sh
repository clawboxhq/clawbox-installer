#!/bin/bash
# ClawBox One-Click Installer
# Automatically detects platform and installs ClawBox CLI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Version
VERSION="${CLAWBOX_VERSION:-0.4.0}"
BASE_URL="https://github.com/clawboxhq/clawbox-installer/releases/download/v${VERSION}"

# Detect platform
detect_platform() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    ARCH=$(uname -m)
    
    case "$ARCH" in
        x86_64|amd64) ARCH="amd64" ;;
        arm64|aarch64) ARCH="arm64" ;;
        *)
            echo -e "${RED}Error: Unsupported architecture: $ARCH${NC}"
            exit 1
            ;;
    esac
    
    BINARY_NAME="clawbox-${VERSION}-${OS}-${ARCH}"
}

# Check if directory is in PATH
is_in_path() {
    echo "$PATH" | grep -q ":$1:" || echo "$PATH" | grep -q "^$1:" || echo "$PATH" | grep -q ":$1$"
}

# Add to PATH in shell profile
add_to_path() {
    local install_dir="$1"
    local shell_profile=""
    
    # Detect shell
    if [ -n "$ZSH_VERSION" ]; then
        shell_profile="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_profile="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            shell_profile="$HOME/.bash_profile"
        fi
    fi
    
    if [ -z "$shell_profile" ]; then
        shell_profile="$HOME/.profile"
    fi
    
    # Check if already in PATH
    if ! is_in_path "$install_dir"; then
        echo "" >> "$shell_profile"
        echo "# Added by ClawBox installer" >> "$shell_profile"
        echo "export PATH=\"\$PATH:$install_dir\"" >> "$shell_profile"
        echo -e "${GREEN}Added $install_dir to PATH in $shell_profile${NC}"
        echo -e "${YELLOW}Please restart your terminal or run: source $shell_profile${NC}"
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"
    
    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$output"
    else
        echo -e "${RED}Error: curl or wget required${NC}"
        exit 1
    fi
}

# Main installation
install_clawbox() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════╗"
    echo "║        ClawBox Installer v${VERSION}        ║"
    echo "║    Secure AI Assistant in a Box         ║"
    echo "╚════════════════════════════════════════╝"
    echo -e "${NC}"
    
    detect_platform
    
    echo -e "${BLUE}Detected Platform:${NC} $OS"
    echo -e "${BLUE}Detected Architecture:${NC} $ARCH"
    echo ""
    
    # Determine install directory
    INSTALL_DIR="${CLAWBOX_INSTALL_DIR:-/usr/local/bin}"
    
    # Check if we can write to install directory
    if [ ! -w "$INSTALL_DIR" ]; then
        # Try user local bin
        USER_LOCAL="$HOME/.local/bin"
        mkdir -p "$USER_LOCAL"
        INSTALL_DIR="$USER_LOCAL"
        echo -e "${YELLOW}Using user directory: $INSTALL_DIR${NC}"
    fi
    
    # Download binary
    echo -e "${BLUE}Downloading ClawBox...${NC}"
    TEMP_FILE=$(mktemp)
    download "$BASE_URL/$BINARY_NAME" "$TEMP_FILE"
    
    # Make executable
    chmod +x "$TEMP_FILE"
    
    # Move to install directory
    FINAL_PATH="$INSTALL_DIR/clawbox"
    mv "$TEMP_FILE" "$FINAL_PATH"
    
    echo -e "${GREEN}✓ Installed to: $FINAL_PATH${NC}"
    
    # Add to PATH if needed
    if ! is_in_path "$INSTALL_DIR"; then
        add_to_path "$INSTALL_DIR"
    fi
    
    # Verify installation
    if [ -x "$FINAL_PATH" ]; then
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║      Installation Successful!           ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}Version:${NC} $($FINAL_PATH version 2>/dev/null | head -1 || echo "$VERSION")"
        echo ""
        echo -e "${BLUE}Next Steps:${NC}"
        echo "  1. Open a new terminal (or source your profile)"
        echo "  2. Run: clawbox install"
        echo "  3. Follow the interactive setup"
        echo ""
        echo -e "${BLUE}Documentation:${NC} https://github.com/clawboxhq/clawbox-installer"
    fi
}

# Uninstall
uninstall_clawbox() {
    INSTALL_DIR="${CLAWBOX_INSTALL_DIR:-/usr/local/bin}"
    FINAL_PATH="$INSTALL_DIR/clawbox"
    
    if [ -f "$FINAL_PATH" ]; then
        rm -f "$FINAL_PATH"
        echo -e "${GREEN}ClawBox uninstalled successfully${NC}"
    else
        echo -e "${YELLOW}ClawBox not found at $FINAL_PATH${NC}"
    fi
}

# Parse arguments
case "${1:-install}" in
    install)
        install_clawbox
        ;;
    uninstall)
        uninstall_clawbox
        ;;
    --version|-v)
        echo "clawbox-installer $VERSION"
        ;;
    --help|-h)
        echo "ClawBox One-Click Installer"
        echo ""
        echo "Usage: curl -fsSL https://clawbox.ai/install.sh | bash"
        echo ""
        echo "Options:"
        echo "  install     Install ClawBox (default)"
        echo "  uninstall   Remove ClawBox"
        echo "  --version   Show installer version"
        echo "  --help      Show this help"
        echo ""
        echo "Environment Variables:"
        echo "  CLAWBOX_VERSION     Version to install (default: $VERSION)"
        echo "  CLAWBOX_INSTALL_DIR Installation directory (default: /usr/local/bin)"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run 'curl -fsSL https://clawbox.ai/install.sh | bash -s -- --help' for usage"
        exit 1
        ;;
esac
