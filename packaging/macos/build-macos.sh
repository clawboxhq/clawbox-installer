#!/bin/bash
# ClawBox macOS Installer
# Creates a simple .pkg installer for macOS

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-arm64}"
BUILD_DIR="build/macos"
SOURCE_DIR="../.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0;31m'

echo -e "${BLUE}Building ClawBox v${VERSION} for macOS ${ARCH}${NC}"

# Build binary
echo -e "${BLUE}Building binary...${NC}"
mkdir -p "$BUILD_DIR/root/usr/local/bin"
mkdir -p "$BUILD_DIR/root/Applications"

CGO_ENABLED=0 GOOS=darwin GOARCH=$ARCH go build -ldflags "-s -w -X main.Version=$VERSION" -o "$BUILD_DIR/root/usr/local/bin/clawbox" ./cmd/clawbox

# Copy completions
mkdir -p "$BUILD_DIR/root/usr/local/share/bash-completion/completions"
mkdir -p "$BUILD_DIR/root/usr/local/share/zsh/site-functions"
mkdir -p "$BUILD_DIR/root/usr/local/share/fish/vendor_completions.d"

"$BUILD_DIR/root/usr/local/bin/clawbox" completion bash > "$BUILD_DIR/root/usr/local/share/bash-completion/completions/clawbox"
"$BUILD_DIR/root/usr/local/bin/clawbox" completion zsh > "$BUILD_DIR/root/usr/local/share/zsh/site-functions/_clawbox"
"$BUILD_DIR/root/usr/local/bin/clawbox" completion fish > "$BUILD_DIR/root/usr/local/share/fish/vendor_completions.d/clawbox.fish"

# Create post-install script
cat > "$BUILD_DIR/scripts/postinstall" << 'EOF'
#!/bin/bash
echo "ClawBox installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal"
echo "  2. Run: clawbox install"
echo "  3. Follow the interactive setup"
EOF
chmod 755 "$BUILD_DIR/scripts/postinstall"

# Create package
echo -e "${BLUE}Creating installer package...${NC}"

pkgbuild \
    --root "$BUILD_DIR/root" \
    --scripts "$BUILD_DIR/scripts" \
    --identifier com.clawbox.installer \
    --version "$VERSION" \
    --install-location / \
    "clawbox-${VERSION}-macos-${ARCH}.pkg"

echo -e "${GREEN}Created: clawbox-${VERSION}-macos-${ARCH}.pkg${NC}"

# Create DMG wrapper (optional, requires hdiutil)
echo -e "${BLUE}Creating DMG...${NC}"
mkdir -p "$BUILD_DIR/dmg"
cp "clawbox-${VERSION}-macos-${ARCH}.pkg" "$BUILD_DIR/dmg/InstallClawBox.pkg"

# Create a simple README for the DMG
cat > "$BUILD_DIR/dmg/README.txt" << EOF
ClawBox $VERSION - Secure AI Assistant in a Box

Installation:
1. Double-click "InstallClawBox.pkg"
2. Follow the installation wizard
3. Open Terminal and run: clawbox install

Documentation: https://github.com/clawboxhq/clawbox-installer
EOF

# Create DMG
hdiutil create -volname "ClawBox $VERSION" \
    -srcfolder "$BUILD_DIR/dmg" \
    -ov -format UDZO \
    "clawbox-${VERSION}-macos-${ARCH}.dmg"

echo -e "${GREEN}Created: clawbox-${VERSION}-macos-${ARCH}.dmg${NC}"
echo ""
echo "Files created:"
echo "  - clawbox-${VERSION}-macos-${ARCH}.pkg"
echo "  - clawbox-${VERSION}-macos-${ARCH}.dmg"
