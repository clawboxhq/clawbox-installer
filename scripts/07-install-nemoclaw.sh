#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Install NemoClaw via npm

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Install NemoClaw
install_nemoclaw() {
    ui_stage "Installing NemoClaw"
    
    # Check Node.js
    local node_major
    node_major=$(get_node_major_version)
    
    if (( node_major < MIN_NODE_MAJOR )); then
        ui_error "Node.js ${MIN_NODE_MAJOR}+ required (found: ${node_major})"
        ui_info "Run the Node.js installation script first"
        return 1
    fi
    
    # Check if already installed
    if command_exists nemoclaw; then
        ui_success "NemoClaw already installed"
        ui_kv "Path" "$(command -v nemoclaw)"
        
        # Check if openclaw nemoclaw plugin works
        if command_exists openclaw && openclaw nemoclaw status &>/dev/null; then
            ui_success "NemoClaw plugin is active"
        fi
        
        return 0
    fi
    
    ui_info "Installing NemoClaw from GitHub..."
    
    # Install via npm
    local install_log
    install_log=$(create_temp_file)
    
    local npm_quiet="--silent"
    if [[ "${VERBOSE:-0}" == "1" ]]; then
        npm_quiet=""
    fi
    
    if ! ui_run_spinner "Installing NemoClaw package" \
        npm install $npm_quiet --no-fund --no-audit -g git+https://github.com/NVIDIA/NemoClaw.git \
        > "$install_log" 2>&1; then
        
        ui_error "Failed to install NemoClaw"
        
        if grep -q "EEXIST" "$install_log" 2>/dev/null; then
            ui_warn "Existing installation conflict detected"
            ui_info "Try: npm install -g --force git+https://github.com/NVIDIA/NemoClaw.git"
        fi
        
        if [[ -s "$install_log" ]]; then
            tail -n 30 "$install_log" >&2
        fi
        
        rm -f "$install_log"
        return 1
    fi
    
    rm -f "$install_log"
    
    # Verify installation
    local npm_bin
    npm_bin=$(npm config get prefix 2>/dev/null)/bin
    
    # Create shim if needed
    local shim_dir="$HOME/.local/bin"
    local shim_path="${shim_dir}/nemoclaw"
    
    if [[ -x "${npm_bin}/nemoclaw" ]]; then
        # Ensure PATH
        if [[ ":$PATH:" != *":$npm_bin:"* ]] && [[ ":$PATH:" != *":$shim_dir:"* ]]; then
            ensure_dir "$shim_dir"
            ln -sf "${npm_bin}/nemoclaw" "$shim_path"
            export PATH="$shim_dir:$PATH"
            ui_info "Created shim at $shim_path"
        fi
    fi
    
    # Verify
    if command_exists nemoclaw; then
        ui_success "NemoClaw installed successfully"
        ui_kv "Path" "$(command -v nemoclaw)"
    else
        # Check if it's in npm_bin
        if [[ -x "${npm_bin}/nemoclaw" ]]; then
            ui_success "NemoClaw installed"
            ui_kv "Path" "${npm_bin}/nemoclaw"
            ui_warn "Add to PATH: export PATH=\"${npm_bin}:\$PATH\""
        elif [[ -x "$shim_path" ]]; then
            ui_success "NemoClaw installed"
            ui_kv "Path" "$shim_path"
        else
            ui_error "NemoClaw installation could not be verified"
            return 1
        fi
    fi
    
    return 0
}

# Main
install_nemoclaw "$@"
