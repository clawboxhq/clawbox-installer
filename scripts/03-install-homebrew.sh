#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Install Homebrew if not present

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Install Homebrew
install_homebrew() {
    ui_stage "Installing Homebrew"
    
    local brew_bin
    brew_bin=$(resolve_brew_bin || true)
    
    if [[ -n "$brew_bin" ]]; then
        ui_success "Homebrew already installed"
        activate_brew_for_session || true
        
        local brew_version
        brew_version=$("$brew_bin" --version 2>/dev/null | head -1 || echo "unknown")
        ui_kv "Version" "$brew_version"
        ui_kv "Path" "$brew_bin"
        
        return 0
    fi
    
    ui_info "Homebrew not found, installing..."
    
    # Check if user is admin (required for Homebrew installation on macOS)
    if ! is_root && ! id -Gn "$(id -un)" 2>/dev/null | grep -qw "admin"; then
        ui_error "Homebrew installation requires an Administrator account"
        echo ""
        echo "Current user ($(id -un)) is not in the admin group."
        echo ""
        echo "Fix options:"
        echo "  1) Use an Administrator account and re-run the installer."
        echo "  2) Ask an Administrator to grant admin rights:"
        echo "     sudo dseditgroup -o edit -a $(id -un) -t user admin"
        echo ""
        echo "Then sign out/in and retry."
        return 1
    fi
    
    # Install Homebrew
    local install_log
    install_log=$(create_temp_file)
    
    if ! ui_run_spinner "Installing Homebrew" \
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        > "$install_log" 2>&1; then
        
        ui_error "Failed to install Homebrew"
        if [[ -s "$install_log" ]]; then
            tail -n 20 "$install_log" >&2
        fi
        rm -f "$install_log"
        return 1
    fi
    
    rm -f "$install_log"
    
    # Activate for current session
    activate_brew_for_session || true
    
    # Verify installation
    brew_bin=$(resolve_brew_bin || true)
    if [[ -z "$brew_bin" ]]; then
        ui_error "Homebrew installed but brew not found on PATH"
        ui_info "You may need to restart your terminal or run:"
        echo "  eval \"\$(${brew_bin} shellenv)\""
        return 1
    fi
    
    ui_success "Homebrew installed successfully"
    ui_kv "Path" "$brew_bin"
    
    return 0
}

# Main
install_homebrew "$@"
