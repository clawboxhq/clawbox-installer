#!/bin/bash
# ClawBox macOS DMG Creator
# Creates a user-friendly DMG installer for macOS

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-arm64}"
BUILD_DIR="build/dmg"
APP_NAME="ClawBox"
DMG_NAME="ClawBox-${VERSION}-macos-${ARCH}.dmg"

echo "Creating ${DMG_NAME}..."

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Create .app bundle structure
APP_DIR="${BUILD_DIR}/${APP_NAME}.app"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# Copy binary to .app bundle
BINARY_NAME="clawbox-${VERSION}-darwin-${ARCH}"
if [ -f "${BINARY_NAME}" ]; then
    cp "${BINARY_NAME}" "${APP_DIR}/Contents/MacOS/clawbox"
else
    echo "Building binary..."
    CGO_ENABLED=0 GOOS=darwin GOARCH=${ARCH} go build -ldflags "-s -w -X main.Version=${VERSION}" -o "${APP_DIR}/Contents/MacOS/clawbox" ./cmd/clawbox
fi
chmod +x "${APP_DIR}/Contents/MacOS/clawbox"

# Create Info.plist
cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>clawbox</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.clawbox.app</string>
    <key>CFBundleName</key>
    <string>ClawBox</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key>
            <string>Folder</string>
            <key>LSHandlerRank</key>
            <string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.folder</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create a simple app icon (placeholder - use default terminal icon style)
# In production, you'd use a real .icns file
if [ -f "packaging/macos/AppIcon.icns" ]; then
    cp "packaging/macos/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
fi

# Create DMG folder structure
DMG_DIR="${BUILD_DIR}/dmg"
mkdir -p "${DMG_DIR}"

# Copy .app to DMG folder
cp -R "${APP_DIR}" "${DMG_DIR}/${APP_NAME}.app"

# Create Applications symlink
ln -s /Applications "${DMG_DIR}/Applications"

# Create README
cat > "${DMG_DIR}/README.txt" << EOF
ClawBox ${VERSION} - Secure AI Assistant in a Box

Installation Instructions:
1. Drag "ClawBox.app" to the "Applications" folder
2. Open Applications folder and double-click "ClawBox"
3. If you see "unidentified developer" warning:
   - Right-click (or Control-click) ClawBox.app
   - Select "Open" from the menu
   - Click "Open" in the dialog

First Run:
1. Open Terminal
2. Run: clawbox install
3. Follow the interactive setup

Documentation: https://github.com/clawboxhq/clawbox-installer
EOF

# Create background image with arrow
mkdir -p "${DMG_DIR}/.background"
cat > "${DMG_DIR}/.background/background.svg" << 'SVGEOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg width="600" height="400" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#1a1a2e"/>
      <stop offset="100%" style="stop-color:#16213e"/>
    </linearGradient>
  </defs>
  <rect width="600" height="400" fill="url(#bg)"/>
  <text x="300" y="50" font-family="Arial, sans-serif" font-size="28" fill="#ffffff" text-anchor="middle" font-weight="bold">ClawBox</text>
  <text x="300" y="80" font-family="Arial, sans-serif" font-size="14" fill="#aaaaaa" text-anchor="middle">Secure AI Assistant in a Box</text>
  <text x="300" y="350" font-family="Arial, sans-serif" font-size="12" fill="#888888" text-anchor="middle">Drag ClawBox.app to Applications folder</text>
</svg>
SVGEOF

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "ClawBox ${VERSION}" -srcfolder "${DMG_DIR}" -ov -format UDZO "${DMG_NAME}"

echo ""
echo "✓ Created: ${DMG_NAME}"
echo ""
echo "Note: This DMG is unsigned. Users will see a security warning."
echo "They can bypass it by right-clicking the app and selecting 'Open'."
