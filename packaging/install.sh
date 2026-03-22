#!/bin/bash
# ClawBox One-Click Installer
# Automatically detects platform, installs ClawBox CLI, and starts first sandbox

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Version
VERSION="${CLAWBOX_VERSION:-0.1.0}"
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

    if ! is_in_path "$install_dir"; then
        echo "" >> "$shell_profile"
        echo "# Added by ClawBox installer" >> "$shell_profile"
        echo "export PATH=\"\$PATH:$install_dir\"" >> "$shell_profile"
        echo -e "${GREEN}✓ Added $install_dir to PATH in $shell_profile${NC}"
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

# Detect available LLM provider
detect_provider() {
    if command -v ollama &> /dev/null; then
        echo "ollama"
        return 0
    fi
    
    # Check for running Ollama
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        echo "ollama"
        return 0
    fi
    
    echo "none"
}

# Get default model for provider
get_default_model() {
    local provider="$1"
    
    case "$provider" in
        ollama)
            # Check if llama3.2 is available
            if curl -s http://localhost:11434/api/tags 2>/dev/null | grep -q "llama3.2"; then
                echo "llama3.2"
            elif curl -s http://localhost:11434/api/tags 2>/dev/null | grep -q "llama3"; then
                echo "llama3"
            else
                echo "llama3.2"
            fi
            ;;
        *)
            echo "llama3.2"
            ;;
    esac
}

# Create initial configuration
create_config() {
    local provider="$1"
    local model="$2"
    local config_dir="$HOME/.clawbox"
    local config_file="$config_dir/config.json"
    
    mkdir -p "$config_dir"
    
    cat > "$config_file" << EOF
{
  "defaultProvider": "$provider",
  "providers": {
    "$provider": {
      "name": "$provider",
      "type": "$provider",
      "endpoint": "http://localhost:11434",
      "defaultModel": "$model"
    }
  },
  "sandboxes": []
}
EOF
    
    echo -e "${GREEN}✓ Created configuration at $config_file${NC}"
}

# Main installation
install_clawbox() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║         🦞 ClawBox Installer v${VERSION}          ║"
    echo "║     Run AI Locally. Execute Code Safely.          ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"

    detect_platform

    echo -e "${BLUE}Platform:${NC} $OS"
    echo -e "${BLUE}Architecture:${NC} $ARCH"
    echo ""

    # Determine install directory
    INSTALL_DIR="${CLAWBOX_INSTALL_DIR:-/usr/local/bin}"

    # Check if we can write to install directory
    if [ ! -w "$INSTALL_DIR" ]; then
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

    # Detect provider
    echo ""
    echo -e "${BLUE}Detecting LLM providers...${NC}"
    PROVIDER=$(detect_provider)
    
    if [ "$PROVIDER" = "none" ]; then
        echo -e "${YELLOW}⚠ No local LLM detected${NC}"
        echo ""
        echo "To use ClawBox, you need a local LLM provider."
        echo ""
        echo -e "${CYAN}Recommended: Install Ollama${NC}"
        echo "  macOS:   brew install ollama"
        echo "  Linux:   curl -fsSL https://ollama.ai/install.sh | sh"
        echo "  Windows: winget install Ollama.Ollama"
        echo ""
        echo "After installing Ollama, pull a model:"
        echo "  ollama pull llama3.2"
        echo ""
        echo "Then run: clawbox install"
    else
        MODEL=$(get_default_model "$PROVIDER")
        echo -e "${GREEN}✓ Detected $PROVIDER${NC}"
        
        # Create config
        create_config "$PROVIDER" "$MODEL"
        
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║           🎉 Installation Complete!               ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${BLUE}ClawBox is ready to use!${NC}"
        echo ""
        echo -e "${CYAN}Try:${NC}"
        echo "  clawbox version"
        echo "  clawbox doctor"
        echo ""
        echo -e "${CYAN}Create a sandbox:${NC}"
        echo "  clawbox sandbox create dev --provider $PROVIDER --model $MODEL"
        echo "  clawbox sandbox start dev"
        echo ""
        echo -e "${CYAN}Or run the full setup:${NC}"
        echo "  clawbox install"
    fi
    
    echo ""
    echo -e "${BLUE}Documentation:${NC} https://github.com/clawboxhq/clawbox-installer"
    echo -e "${BLUE}Discord:${NC} https://discord.gg/XFpfPv9Uvx"
}

# Uninstall
uninstall_clawbox() {
    INSTALL_DIR="${CLAWBOX_INSTALL_DIR:-/usr/local/bin}"
    FINAL_PATH="$INSTALL_DIR/clawbox"
    CONFIG_DIR="$HOME/.clawbox"

    if [ -f "$FINAL_PATH" ]; then
        rm -f "$FINAL_PATH"
        echo -e "${GREEN}✓ Removed binary from $FINAL_PATH${NC}"
    fi

    if [ -d "$CONFIG_DIR" ]; then
        echo -e "${YELLOW}Configuration preserved at $CONFIG_DIR${NC}"
        echo "To remove: rm -rf $CONFIG_DIR"
    fi

    echo -e "${GREEN}ClawBox uninstalled successfully${NC}"
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
        echo "Usage: curl -fsSL https://clawbox.ai/install | bash"
        echo ""
        echo "Options:"
        echo "  install    Install ClawBox (default)"
        echo "  uninstall  Remove ClawBox"
        echo "  --version  Show installer version"
        echo "  --help     Show this help"
        echo ""
        echo "Environment Variables:"
        echo "  CLAWBOX_VERSION     Version to install (default: $VERSION)"
        echo "  CLAWBOX_INSTALL_DIR Installation directory (default: /usr/local/bin)"
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo "Run 'curl -fsSL https://clawbox.ai/install | bash -s -- --help' for usage"
        exit 1
        ;;
esac
