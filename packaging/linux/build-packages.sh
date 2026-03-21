#!/bin/bash
# Build Linux packages for ClawBox
# Creates .deb and .rpm packages

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-amd64}"
BUILD_DIR="build/packages"
SOURCE_DIR="."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Building ClawBox v${VERSION} packages for ${ARCH}${NC}"

# Build the binary first
echo -e "${BLUE}Building binary...${NC}"
mkdir -p "$BUILD_DIR/usr/bin"
CGO_ENABLED=0 GOOS=linux GOARCH=$ARCH go build -ldflags "-s -w -X main.Version=$VERSION" -o "$BUILD_DIR/usr/bin/clawbox" ./cmd/clawbox

# Copy completions
echo -e "${BLUE}Copying shell completions...${NC}"
mkdir -p "$BUILD_DIR/usr/share/bash-completion/completions"
mkdir -p "$BUILD_DIR/usr/share/zsh/vendor-completions"
mkdir -p "$BUILD_DIR/usr/share/fish/vendor_completions.d"

./clawbox completion bash > "$BUILD_DIR/usr/share/bash-completion/completions/clawbox"
./clawbox completion zsh > "$BUILD_DIR/usr/share/zsh/vendor-completions/_clawbox"
./clawbox completion fish > "$BUILD_DIR/usr/share/fish/vendor_completions.d/clawbox.fish"

# Create DEBIAN control file for .deb
echo -e "${BLUE}Creating .deb package...${NC}"
mkdir -p "$BUILD_DIR/DEBIAN"

cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: clawbox
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: ClawBox Team <team@clawbox.ai>
Description: Secure AI Assistant in a Box
 One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw
 with secure sandboxing and persistent volume mounting.
Homepage: https://github.com/clawboxhq/clawbox-installer
EOF

# Create postinst script
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
# Add clawbox to PATH if not already
if ! grep -q "clawbox" /etc/profile.d/clawbox.sh 2>/dev/null; then
    echo 'export PATH="$PATH:/usr/bin"' > /etc/profile.d/clawbox.sh
    chmod 644 /etc/profile.d/clawbox.sh
fi
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Build .deb package
dpkg-deb --build "$BUILD_DIR" "clawbox_${VERSION}_${ARCH}.deb"
echo -e "${GREEN}Created: clawbox_${VERSION}_${ARCH}.deb${NC}"

# Clean up for .rpm build
echo -e "${BLUE}Creating .rpm package...${NC}"

# Create RPM spec file
mkdir -p "$BUILD_DIR/rpm"
cat > "$BUILD_DIR/rpm/clawbox.spec" << EOF
Name:           clawbox
Version:        $VERSION
Release:        1%{?dist}
Summary:        Secure AI Assistant in a Box

License:        Apache-2.0
URL:            https://github.com/clawboxhq/clawbox-installer
Source0:        clawbox-%{version}.tar.gz

BuildArch:      $(echo $ARCH | sed 's/amd64/x86_64/' | sed 's/arm64/aarch64/')

%description
One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw
with secure sandboxing and persistent volume mounting.

%prep
%setup -q

%install
mkdir -p %{buildroot}/usr/bin
install -m 755 clawbox %{buildroot}/usr/bin/clawbox

mkdir -p %{buildroot}/usr/share/bash-completion/completions
install -m 644 completions/bash %{buildroot}/usr/share/bash-completion/completions/clawbox

mkdir -p %{buildroot}/usr/share/zsh/vendor-completions
install -m 644 completions/zsh %{buildroot}/usr/share/zsh/vendor-completions/_clawbox

mkdir -p %{buildroot}/usr/share/fish/vendor_completions.d
install -m 644 completions/fish %{buildroot}/usr/share/fish/vendor_completions.d/clawbox.fish

%files
%doc README.md
%license LICENSE
/usr/bin/clawbox
/usr/share/bash-completion/completions/clawbox
/usr/share/zsh/vendor-completions/_clawbox
/usr/share/fish/vendor_completions.d/clawbox.fish

%post
echo "ClawBox installed successfully!"

%changelog
* $(date '+%a %b %d %Y') ClawBox Team <team@clawbox.ai> - $VERSION-1
- Initial package release
EOF

echo -e "${GREEN}Package creation complete!${NC}"
echo ""
echo "Files created:"
echo "  - clawbox_${VERSION}_${ARCH}.deb"
echo "  - clawbox-${VERSION}.spec (for RPM build)"
