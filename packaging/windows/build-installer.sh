#!/bin/bash
# Build Windows installer using NSIS
# This script creates a Windows setup executable on Linux/macOS

set -e

VERSION="${1:-0.4.0}"
ARCH="${2:-amd64}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build/windows"
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
if [ -f "${PROJECT_ROOT}/dist/${BINARY_NAME}" ]; then
    echo "Using binary from dist/"
    mkdir -p "${BUILD_DIR}"
    cp "${PROJECT_ROOT}/dist/${BINARY_NAME}" "${BUILD_DIR}/"
elif [ -f "${PROJECT_ROOT}/${BINARY_NAME}" ]; then
    echo "Using binary from project root"
    if [ "${PROJECT_ROOT}" != "${BUILD_DIR}" ]; then
        mkdir -p "${BUILD_DIR}"
        cp "${PROJECT_ROOT}/${BINARY_NAME}" "${BUILD_DIR}/"
    fi
else
    echo "Building Windows binary..."
    cd "${PROJECT_ROOT}"
    mkdir -p "${BUILD_DIR}"
    CGO_ENABLED=0 GOOS=windows GOARCH=${ARCH} go build -ldflags "-s -w -X main.Version=${VERSION}" -o "${BUILD_DIR}/${BINARY_NAME}" ./cmd/clawbox
fi

# Create LICENSE.txt for installer
if [ -f "${PROJECT_ROOT}/LICENSE" ]; then
    cp "${PROJECT_ROOT}/LICENSE" "${BUILD_DIR}/LICENSE.txt"
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

cd "${BUILD_DIR}"

# Prepare NSIS script with version substitution
sed "s/\${VERSION}/${VERSION}/g" "${SCRIPT_DIR}/clawbox-installer.nsi" > clawbox-installer.nsi

# Build installer (binary is already in BUILD_DIR)
echo "Building NSIS installer..."
makensis -DVERSION=${VERSION} clawbox-installer.nsi

# Output location
if [ -f "${INSTALLER_NAME}" ]; then
    mv "${INSTALLER_NAME}" "${PROJECT_ROOT}/${INSTALLER_NAME}"
    echo ""
    echo "✓ Created: ${PROJECT_ROOT}/${INSTALLER_NAME}"
else
    echo "Error: Installer was not created"
    exit 1
fi

echo ""
echo "Note: This installer is unsigned. Users may see a Windows Defender warning."
echo "They can click 'Run anyway' to proceed with installation."
