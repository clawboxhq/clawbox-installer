#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Check system prerequisites (RAM, disk, network)

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Minimum requirements
readonly MIN_RAM_GB=8
readonly MIN_DISK_GB=20

# Check prerequisites
check_prerequisites() {
    local errors=0
    
    ui_stage "Checking System Prerequisites"
    
    # Check RAM
    local ram_gb
    ram_gb=$(get_total_ram_gb)
    ui_kv "Memory" "${ram_gb} GB"
    
    if (( ram_gb < MIN_RAM_GB )); then
        ui_warn "Low memory detected (minimum ${MIN_RAM_GB} GB recommended)"
        ui_info "Configure at least 8 GB swap: https://docs.openclaw.ai/troubleshooting/swap"
    else
        ui_success "Sufficient memory"
    fi
    
    # Check disk space
    local disk_gb
    disk_gb=$(get_available_disk_gb "$HOME")
    ui_kv "Available Disk" "${disk_gb} GB"
    
    if (( disk_gb < MIN_DISK_GB )); then
        ui_error "Insufficient disk space (minimum ${MIN_DISK_GB} GB required)"
        ((errors++))
    else
        ui_success "Sufficient disk space"
    fi
    
    # Check internet connectivity
    ui_info "Checking internet connectivity..."
    if ! ping -c 1 -W 5 github.com &>/dev/null; then
        ui_error "No internet connectivity (cannot reach github.com)"
        ((errors++))
    else
        ui_success "Internet connectivity OK"
    fi
    
    # Check for existing installations
    check_existing_installations
    
    if (( errors > 0 )); then
        return 1
    fi
    
    return 0
}

# Check for existing installations
check_existing_installations() {
    ui_info "Checking for existing installations..."
    
    local found=()
    
    # Check for OpenShell
    if command_exists openshell; then
        local openshell_version
        openshell_version=$(openshell --version 2>/dev/null || echo "unknown")
        found+=("OpenShell: ${openshell_version}")
    fi
    
    # Check for NemoClaw
    if command_exists nemoclaw; then
        found+=("NemoClaw: installed")
    fi
    
    # Check for OpenClaw
    if command_exists openclaw; then
        local openclaw_version
        openclaw_version=$(openclaw --version 2>/dev/null || echo "unknown")
        found+=("OpenClaw: ${openclaw_version}")
    fi
    
    if (( ${#found[@]} > 0 )); then
        ui_warn "Existing installations detected:"
        for item in "${found[@]}"; do
            ui_info "  • ${item}"
        done
        echo ""
        if is_interactive; then
            if ! ui_confirm "Continue with installation?"; then
                return 1
            fi
        fi
    else
        ui_success "No existing installations detected"
    fi
    
    return 0
}

# Main
check_prerequisites "$@"
