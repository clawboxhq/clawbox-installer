#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Install Node.js 22+ via Homebrew

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Install Node.js
install_nodejs() {
    ui_stage "Installing Node.js"
    
    # Ensure Homebrew is active
    activate_brew_for_session || true
    
    local brew_bin
    brew_bin=$(resolve_brew_bin || true)
    
    if [[ -z "$brew_bin" ]]; then
        ui_error "Homebrew not found. Run the Homebrew installation script first."
        return 1
    fi
    
    # Check current Node version
    local node_major
    node_major=$(get_node_major_version)
    
    if (( node_major >= MIN_NODE_MAJOR )); then
        ui_success "Node.js ${node_major} already installed"
        
        local node_path npm_version
        node_path=$(command -v node 2>/dev/null || echo "unknown")
        npm_version=$(npm -v 2>/dev/null || echo "unknown")
        
        ui_kv "Node.js" "$(node -v 2>/dev/null || echo 'unknown') ($node_path)"
        ui_kv "npm" "$npm_version"
        
        return 0
    fi
    
    if [[ "$node_major" != "0" ]]; then
        ui_info "Node.js ${node_major} found, upgrading to ${MIN_NODE_MAJOR}+"
    else
        ui_info "Node.js not found, installing..."
    fi
    
    # Install node@22
    local install_log
    install_log=$(create_temp_file)
    
    if ! ui_run_spinner "Installing node@22 via Homebrew" \
        "$brew_bin" install node@22 \
        > "$install_log" 2>&1; then
        
        # Check if it's already installed
        if grep -q "already installed" "$install_log" 2>/dev/null; then
            ui_info "node@22 already installed via Homebrew"
        else
            ui_error "Failed to install Node.js"
            if [[ -s "$install_log" ]]; then
                tail -n 20 "$install_log" >&2
            fi
            rm -f "$install_log"
            return 1
        fi
    fi
    
    rm -f "$install_log"
    
    # Link node@22
    ui_info "Linking node@22..."
    "$brew_bin" link node@22 --overwrite --force 2>/dev/null || true
    
    # Get the Homebrew node@22 prefix
    local node_prefix
    node_prefix=$("$brew_bin" --prefix node@22 2>/dev/null || true)
    
    if [[ -n "$node_prefix" && -x "${node_prefix}/bin/node" ]]; then
        # Add to PATH for current session
        export PATH="${node_prefix}/bin:$PATH"
        
        # Verify it works
        local new_version
        new_version=$("${node_prefix}/bin/node" -v 2>/dev/null || echo "unknown")
        ui_success "Node.js ${new_version} installed"
        ui_kv "Path" "${node_prefix}/bin/node"
    fi
    
    # Final verification
    local final_major
    final_major=$(get_node_major_version)
    
    if (( final_major < MIN_NODE_MAJOR )); then
        ui_warn "Node.js installed but version may not be active in current shell"
        ui_info "Add to your shell profile:"
        
        local profile
        profile=$(get_shell_profile)
        
        if [[ -n "$node_prefix" ]]; then
            echo ""
            echo "  echo 'export PATH=\"${node_prefix}/bin:\$PATH\"' >> ${profile}"
            echo ""
            echo "Then restart your terminal or run: source ${profile}"
        fi
        
        return 1
    fi
    
    ui_kv "Node.js" "$(node -v 2>/dev/null)"
    ui_kv "npm" "$(npm -v 2>/dev/null)"
    
    return 0
}

# Main
install_nodejs "$@"
