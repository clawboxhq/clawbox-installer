#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Verify installation and run tests

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Verify installation
verify_installation() {
    local project_dir="${1:-.}"
    local sandbox_name="${2:-my-assistant}"
    
    ui_stage "Verifying Installation"
    
    local errors=0
    
    # Check Homebrew
    if command_exists brew; then
        ui_success "Homebrew: $(brew --version 2>/dev/null | head -1 || echo 'installed')"
    else
        ui_error "Homebrew: not found"
        ((errors++))
    fi
    
    # Check Node.js
    if command_exists node; then
        local node_major
        node_major=$(get_node_major_version)
        if (( node_major >= 22 )); then
            ui_success "Node.js: $(node -v)"
        else
            ui_warn "Node.js: $(node -v) (version < 22)"
        fi
    else
        ui_error "Node.js: not found"
        ((errors++))
    fi
    
    # Check Docker
    if command_exists docker; then
        if is_docker_running; then
            ui_success "Docker: running ($(docker --version 2>/dev/null || echo 'unknown'))"
        else
            ui_warn "Docker: installed but not running"
        fi
    else
        ui_error "Docker: not found"
        ((errors++))
    fi
    
    # Check OpenShell
    if command_exists openshell; then
        ui_success "OpenShell: $(openshell --version 2>/dev/null || echo 'installed')"
    else
        ui_error "OpenShell: not found"
        ((errors++))
    fi
    
    # Check NemoClaw
    if command_exists nemoclaw; then
        ui_success "NemoClaw: installed ($(command -v nemoclaw))"
    else
        ui_error "NemoClaw: not found"
        ((errors++))
    fi
    
    # Check sandbox
    ui_info "Checking sandbox status..."
    
    if openshell sandbox list 2>/dev/null | grep -qE "^${sandbox_name}\s"; then
        ui_success "Sandbox '${sandbox_name}': exists"
        
        # Get sandbox info
        local sandbox_status
        sandbox_status=$(openshell sandbox get "$sandbox_name" 2>/dev/null || echo "unknown")
        ui_info "Status: $sandbox_status"
    else
        ui_warn "Sandbox '${sandbox_name}': not found"
        ui_info "Run the sandbox creation script first"
    fi
    
    # Check data directory
    local openclaw_data="${project_dir}/openclaw-data"
    if [[ -d "$openclaw_data" ]]; then
        ui_success "Data directory: $openclaw_data"
        
        if [[ -f "${openclaw_data}/.openclaw/openclaw.json" ]]; then
            ui_success "OpenClaw config: present"
        else
            ui_warn "OpenClaw config: missing"
        fi
    else
        ui_warn "Data directory: not found"
    fi
    
    # Test inference (optional)
    if [[ "${SKIP_INFERENCE_TEST:-0}" != "1" ]]; then
        test_inference "$sandbox_name"
    fi
    
    # Summary
    echo ""
    
    if (( errors > 0 )); then
        ui_error "Verification completed with $errors error(s)"
        return 1
    fi
    
    ui_success "All verifications passed"
    return 0
}

# Test inference endpoint
test_inference() {
    local sandbox_name="$1"
    
    ui_info "Testing inference endpoint..."
    
    local test_response
    test_response=$(openshell inference test 2>/dev/null || echo "failed")
    
    if [[ "$test_response" != "failed" ]]; then
        ui_success "Inference: working"
    else
        ui_warn "Inference: could not test (may require sandbox connection)"
    fi
}

# Main
verify_installation "$@"
