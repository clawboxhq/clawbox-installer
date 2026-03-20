#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Check macOS architecture (Apple Silicon required)

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Check architecture
check_architecture() {
    local arch
    arch=$(detect_arch)
    
    ui_stage "Checking System Architecture"
    
    if [[ "$arch" != "arm64" ]]; then
        ui_error "Unsupported architecture: ${arch}"
        echo ""
        echo "This installer requires Apple Silicon (arm64/aarch64)."
        echo "Intel-based Macs (x86_64) are not supported."
        echo ""
        echo "Alternatives:"
        echo "  • Use a cloud VM with ARM architecture"
        echo "  • Use standard OpenClaw installation: curl -fsSL https://openclaw.ai/install.sh | bash"
        return 1
    fi
    
    ui_success "Apple Silicon detected (arm64)"
    
    # Check macOS version
    local macos_version
    macos_version=$(sw_vers -productVersion 2>/dev/null || echo "0.0.0")
    ui_kv "macOS Version" "$macos_version"
    
    if ! check_macos_version; then
        ui_warn "macOS version older than recommended (14.0+)"
        ui_info "Continuing anyway, but some features may not work correctly"
    fi
    
    return 0
}

# Main
check_architecture "$@"
