#!/bin/bash
# Build Windows installer using NSIS
# This script creates a Windows setup executable on Linux/macOS

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-amd64}"
BUILD_DIR="build/windows"
NSIS_SCRIPT="packaging/windows/clawbox-installer.nsi"
BINARY_NAME="clawbox-${VERSION}-windows-${ARCH}.exe"
INSTALLER_NAME="ClawBox-Setup-${VERSION}.exe"

echo "Building Windows installer for ClawBox v${VERSION}..."

# Create build directory
mkdir -p "${BUILD_DIR}"

# Check if NSIS is installed
if ! command -v makensis &> /dev/null; then
    echo "Error: NSIS not found. Install with: apt-get install nsis (Linux) or brew install nsis (macOS)"
    exit 1
fi

# Build Windows binary if not exists
if [ ! -f "${BINARY_NAME}" ]; then
    echo "Building Windows binary..."
    CGO_ENABLED=0 GOOS=windows GOARCH=${ARCH} go build -ldflags "-s -w -X main.Version=${VERSION}" -o "${BUILD_DIR}/${BINARY_NAME}" ./cmd/clawbox
else
    cp "${BINARY_NAME}" "${BUILD_DIR}/"
fi

# Create LICENSE.txt for installer
if [ -f "LICENSE" ]; then
    cp LICENSE "${BUILD_DIR}/LICENSE.txt"
else
    cat > "${BUILD_DIR}/LICENSE.txt" << EOF
ClawBox ${VERSION}
Apache License 2.0

Copyright 2024 ClawBox Team

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
EOF
fi

# Prepare NSIS script with version substitution
cd "${BUILD_DIR}"
sed "s/\${VERSION}/${VERSION}/g" "../${NSIS_SCRIPT}" > clawbox-installer.nsi

# Copy binary for NSIS
cp "${BINARY_NAME}" .

# Build installer
echo "Building NSIS installer..."
makensis -DVERSION=${VERSION} clawbox-installer.nsi

# Rename output
if [ -f "${INSTALLER_NAME}" ]; then
    mv "${INSTALLER_NAME}" "../${INSTALLER_NAME}"
    echo ""
    echo "✓ Created: ../${INSTALLER_NAME}"
else
    echo "Error: Installer was not created"
    exit 1
fi

echo ""
echo "Note: This installer is unsigned. Users may see a Windows Defender warning."
echo "They can click 'Run anyway' to proceed with installation."
