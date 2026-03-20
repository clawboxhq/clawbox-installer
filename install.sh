#!/bin/bash
# ClawBox One-Line Installer
# Downloads and installs the latest clawbox binary

set -e

# Detect platform
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$ARCH" in
    x86_64|amd64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Set binary name
BINARY="clawbox"
INSTALL_DIR="/usr/local/bin"
VERSION="latest"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version) VERSION="$2"; shift 2 ;;
        --prefix) INSTALL_DIR="$2"; shift 2 ;;
        --help|-h) 
            echo "Usage: curl -fsSL https://clawboxhq.github.io/clawbox-installer/install.sh | bash"
            echo ""
            echo "Options:"
            echo "  --version VERSION   Install specific version (default: latest)"
            echo "  --prefix DIR        Install directory (default: /usr/local/bin)"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "🦞 ClawBox Installer"
echo "=================="
echo ""
echo "Platform: $OS-$ARCH"
echo "Version:  $VERSION"
echo "Install:  $INSTALL_DIR"
echo ""

# Download binary
if [ "$VERSION" = "latest" ]; then
    DOWNLOAD_URL="https://github.com/clawboxhq/clawbox-installer/releases/latest/download/clawbox-$OS-$ARCH"
else
    DOWNLOAD_URL="https://github.com/clawboxhq/clawbox-installer/releases/download/v$VERSION/clawbox-$VERSION-$OS-$ARCH"
fi

echo "Downloading from:"
echo "  $DOWNLOAD_URL"
echo ""

# Download to temp file
TMP_FILE=$(mktemp)
trap "rm -f $TMP_FILE" EXIT

if command -v curl &> /dev/null; then
    curl -fsSL "$DOWNLOAD_URL" -o "$TMP_FILE"
elif command -v wget &> /dev/null; then
    wget -q "$DOWNLOAD_URL" -O "$TMP_FILE"
else
    echo "Error: curl or wget required"
    exit 1
fi

# Make executable
chmod +x "$TMP_FILE"

# Install
echo "Installing to $INSTALL_DIR..."
if [ -w "$INSTALL_DIR" ]; then
    mv "$TMP_FILE" "$INSTALL_DIR/$BINARY"
else
    sudo mv "$TMP_FILE" "$INSTALL_DIR/$BINARY"
fi

# Verify
echo ""
echo "✅ Installed successfully!"
echo ""
echo "Installation:"
"$INSTALL_DIR/$BINARY" version

echo ""
echo "Next steps:"
echo "  1. Run: clawbox install"
echo "  2. Configure: clawbox provider add <name> --type <type>"
echo "  3. Check: clawbox doctor"
echo ""
