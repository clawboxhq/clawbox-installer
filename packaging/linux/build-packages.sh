#!/bin/bash
# Build Linux packages for ClawBox
# Creates .deb and .rpm packages with proper structure for GUI installation

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-amd64}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/packages"
BINARY_NAME="clawbox-${VERSION}-linux-${ARCH}"

echo "Building ClawBox v${VERSION} packages for ${ARCH}"

# Build the binary first
echo "Building binary..."
mkdir -p "$BUILD_DIR"
if [ -f "${PROJECT_ROOT}/${BINARY_NAME}" ]; then
    cp "${PROJECT_ROOT}/${BINARY_NAME}" "$BUILD_DIR/clawbox"
elif [ -f "${PROJECT_ROOT}/dist/${BINARY_NAME}" ]; then
    cp "${PROJECT_ROOT}/dist/${BINARY_NAME}" "$BUILD_DIR/clawbox"
else
    cd "${PROJECT_ROOT}"
    CGO_ENABLED=0 GOOS=linux GOARCH=$ARCH go build -ldflags "-s -w -X main.Version=$VERSION" -o "$BUILD_DIR/clawbox" ./cmd/clawbox
fi
chmod +x "$BUILD_DIR/clawbox"

# Generate shell completions
echo "Generating shell completions..."
mkdir -p "$BUILD_DIR/completions"
"$BUILD_DIR/clawbox" completion bash > "$BUILD_DIR/completions/bash" 2>/dev/null || echo "# bash completion not available" > "$BUILD_DIR/completions/bash"
"$BUILD_DIR/clawbox" completion zsh > "$BUILD_DIR/completions/zsh" 2>/dev/null || echo "# zsh completion not available" > "$BUILD_DIR/completions/zsh"
"$BUILD_DIR/clawbox" completion fish > "$BUILD_DIR/completions/fish" 2>/dev/null || echo "# fish completion not available" > "$BUILD_DIR/completions/fish"

# ============================================
# Build .deb package
# ============================================
echo "Creating .deb package..."

DEB_DIR="$BUILD_DIR/deb"
rm -rf "$DEB_DIR"
mkdir -p "$DEB_DIR/DEBIAN"
mkdir -p "$DEB_DIR/usr/bin"
mkdir -p "$DEB_DIR/usr/share/bash-completion/completions"
mkdir -p "$DEB_DIR/usr/share/zsh/vendor-completions"
mkdir -p "$DEB_DIR/usr/share/fish/vendor_completions.d"
mkdir -p "$DEB_DIR/usr/share/doc/clawbox"
mkdir -p "$DEB_DIR/usr/share/man/man1"

# Copy binary and completions
cp "$BUILD_DIR/clawbox" "$DEB_DIR/usr/bin/"
cp "$BUILD_DIR/completions/bash" "$DEB_DIR/usr/share/bash-completion/completions/clawbox"
cp "$BUILD_DIR/completions/zsh" "$DEB_DIR/usr/share/zsh/vendor-completions/_clawbox"
cp "$BUILD_DIR/completions/fish" "$DEB_DIR/usr/share/fish/vendor_completions.d/clawbox.fish"

# Create man page (simple text)
cat > "$DEB_DIR/usr/share/man/man1/clawbox.1" << 'MANEOF'
.TH CLAWBOX 1 "March 2024" "ClawBox" "User Commands"
.SH NAME
clawbox \- Secure AI Assistant in a Box
.SH SYNOPSIS
.B clawbox
[\fIOPTIONS\fR] [\fICOMMAND\fR]
.SH DESCRIPTION
ClawBox is a one-click cross-platform installer for running AI assistants
securely with sandboxing and persistent volume mounting.
.SH COMMANDS
.TP
.B install
Install and configure ClawBox
.TP
.B version
Show version information
.TP
.B help
Show help information
.SH OPTIONS
.TP
.B \-h, \-\-help
Show help
.TP
.B \-v, \-\-version
Show version
.SH AUTHOR
ClawBox Team <team@clawbox.ai>
.SH "SEE ALSO"
.BR docker(1),
.BR podman(1)
MANEOF
gzip -f "$DEB_DIR/usr/share/man/man1/clawbox.1"

# Create changelog
cat > "$DEB_DIR/usr/share/doc/clawbox/changelog.Debian" << EOF
clawbox (${VERSION}-1) stable; urgency=low

  * Initial release

 -- ClawBox Team <team@clawbox.ai>  $(date -R)
EOF
gzip -f "$DEB_DIR/usr/share/doc/clawbox/changelog.Debian"

# Create control file
cat > "$DEB_DIR/DEBIAN/control" << EOF
Package: clawbox
Version: $VERSION
Section: utils
Priority: optional
Architecture: $ARCH
Maintainer: ClawBox Team <team@clawbox.ai>
Installed-Size: $(du -sk "$DEB_DIR" | cut -f1)
Description: Secure AI Assistant in a Box
 ClawBox is a one-click cross-platform installer for running
 OpenShell + NemoClaw + OpenClaw with secure sandboxing and
 persistent volume mounting.
 .
 Features:
  - One-click installation
  - Secure container sandboxing
  - Persistent volume mounting
  - Cross-platform support (macOS, Linux, Windows)
Homepage: https://github.com/clawboxhq/clawbox-installer
EOF

# Create postinst script
cat > "$DEB_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e
echo "ClawBox installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal"
echo "  2. Run: clawbox install"
echo "  3. Follow the interactive setup"
echo ""
POSTINST
chmod 755 "$DEB_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$DEB_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e
echo "Removing ClawBox..."
PRERM
chmod 755 "$DEB_DIR/DEBIAN/prerm"

# Build .deb
DEB_ARCH=$ARCH
[ "$ARCH" = "amd64" ] && DEB_ARCH="amd64"
[ "$ARCH" = "arm64" ] && DEB_ARCH="arm64"

dpkg-deb --build "$DEB_DIR" "${PROJECT_ROOT}/clawbox_${VERSION}_${DEB_ARCH}.deb"
echo "✓ Created: clawbox_${VERSION}_${DEB_ARCH}.deb"

# ============================================
# Build .rpm package
# ============================================
echo "Creating .rpm package..."

RPM_DIR="$BUILD_DIR/rpm"
rm -rf "$RPM_DIR"
mkdir -p "$RPM_DIR/SOURCES"
mkdir -p "$RPM_DIR/SPECS"
mkdir -p "$RPM_DIR/BUILD"
mkdir -p "$RPM_DIR/RPMS"
mkdir -p "$RPM_DIR/SRPMS"

# Create source tarball for RPM
SRC_DIR="$BUILD_DIR/clawbox-${VERSION}"
rm -rf "$SRC_DIR"
mkdir -p "$SRC_DIR/usr/bin"
mkdir -p "$SRC_DIR/completions"
cp "$BUILD_DIR/clawbox" "$SRC_DIR/usr/bin/"
cp "$BUILD_DIR/completions/"* "$SRC_DIR/completions/"
tar -czf "$RPM_DIR/SOURCES/clawbox-${VERSION}.tar.gz" -C "$BUILD_DIR" "clawbox-${VERSION}"

# Create RPM spec file
RPM_ARCH=$ARCH
[ "$ARCH" = "amd64" ] && RPM_ARCH="x86_64"
[ "$ARCH" = "arm64" ] && RPM_ARCH="aarch64"

cat > "$RPM_DIR/SPECS/clawbox.spec" << EOF
Name: clawbox
Version: $VERSION
Release: 1%{?dist}
Summary: Secure AI Assistant in a Box

License: Apache-2.0
URL: https://github.com/clawboxhq/clawbox-installer
Source0: clawbox-%{version}.tar.gz

BuildArch: $RPM_ARCH
Requires: glibc >= 2.31

%description
ClawBox is a one-click cross-platform installer for running
OpenShell + NemoClaw + OpenClaw with secure sandboxing and
persistent volume mounting.

%prep
%setup -q

%install
mkdir -p %{buildroot}/usr/bin
install -m 755 usr/bin/clawbox %{buildroot}/usr/bin/clawbox

mkdir -p %{buildroot}/usr/share/bash-completion/completions
install -m 644 completions/bash %{buildroot}/usr/share/bash-completion/completions/clawbox

mkdir -p %{buildroot}/usr/share/zsh/vendor-completions
install -m 644 completions/zsh %{buildroot}/usr/share/zsh/vendor-completions/_clawbox

mkdir -p %{buildroot}/usr/share/fish/vendor_completions.d
install -m 644 completions/fish %{buildroot}/usr/share/fish/vendor_completions.d/clawbox.fish

%files
%defattr(-,root,root,-)
/usr/bin/clawbox
/usr/share/bash-completion/completions/clawbox
/usr/share/zsh/vendor-completions/_clawbox
/usr/share/fish/vendor_completions.d/clawbox.fish

%post
echo "ClawBox installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal"
echo "  2. Run: clawbox install"
echo "  3. Follow the interactive setup"
echo ""

%changelog
* $(date '+%a %b %d %Y') ClawBox Team <team@clawbox.ai> - $VERSION-1
- Initial package release
EOF

# Try to build RPM if rpmbuild is available
if command -v rpmbuild &> /dev/null; then
    rpmbuild --define "_topdir $RPM_DIR" -bb "$RPM_DIR/SPECS/clawbox.spec"
    if [ -f "$RPM_DIR/RPMS/$RPM_ARCH/clawbox-${VERSION}-1.$RPM_ARCH.rpm" ]; then
        cp "$RPM_DIR/RPMS/$RPM_ARCH/clawbox-${VERSION}-1.$RPM_ARCH.rpm" "${PROJECT_ROOT}/clawbox-${VERSION}-1.$RPM_ARCH.rpm"
        echo "✓ Created: clawbox-${VERSION}-1.$RPM_ARCH.rpm"
    fi
else
    echo "Note: rpmbuild not available, skipping .rpm creation"
    echo "Spec file available at: $RPM_DIR/SPECS/clawbox.spec"
fi

cd "${PROJECT_ROOT}"
echo ""
echo "Package creation complete!"
echo "Files created:"
ls -la clawbox_${VERSION}_*.deb 2>/dev/null || true
ls -la clawbox-${VERSION}*.rpm 2>/dev/null || true
