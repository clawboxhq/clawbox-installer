#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Install and start Docker Desktop

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Install Docker Desktop
install_docker() {
    ui_stage "Installing Docker Desktop"
    
    # Check if Docker is already installed
    if command_exists docker; then
        local docker_version
        docker_version=$(get_docker_version)
        ui_success "Docker already installed"
        ui_kv "Version" "$docker_version"
        
        # Check if running
        if is_docker_running; then
            ui_success "Docker daemon is running"
            return 0
        else
            ui_info "Docker installed but not running, starting..."
            return start_docker
        fi
    fi
    
    # Ensure Homebrew is active
    activate_brew_for_session || true
    
    local brew_bin
    brew_bin=$(resolve_brew_bin || true)
    
    if [[ -z "$brew_bin" ]]; then
        ui_error "Homebrew not found. Run the Homebrew installation script first."
        return 1
    fi
    
    ui_info "Installing Docker Desktop via Homebrew Cask..."
    
    # Install Docker Desktop
    local install_log
    install_log=$(create_temp_file)
    
    if ! ui_run_spinner "Installing Docker Desktop" \
        "$brew_bin" install --cask docker \
        > "$install_log" 2>&1; then
        
        ui_error "Failed to install Docker Desktop"
        if [[ -s "$install_log" ]]; then
            tail -n 20 "$install_log" >&2
        fi
        rm -f "$install_log"
        return 1
    fi
    
    rm -f "$install_log"
    
    ui_success "Docker Desktop installed"
    
    # Start Docker
    return start_docker
}

# Start Docker Desktop
start_docker() {
    ui_info "Starting Docker Desktop..."
    
    # Open Docker Desktop
    open -a Docker 2>/dev/null || true
    
    # Wait for Docker to be ready
    ui_info "Waiting for Docker daemon (this may take up to 60 seconds)..."
    
    local timeout=60
    local count=0
    
    while ! is_docker_running; do
        if (( count >= timeout )); then
            ui_error "Docker did not start within ${timeout} seconds"
            ui_info "Please open Docker Desktop manually and retry"
            return 1
        fi
        
        ui_progress "$count" "$timeout" "Starting Docker..."
        sleep 1
        ((count++))
    done
    
    ui_progress "$timeout" "$timeout" "Starting Docker..."
    ui_success "Docker daemon is ready"
    
    # Show Docker info
    local docker_version
    docker_version=$(docker --version 2>/dev/null || echo "unknown")
    ui_kv "Version" "$docker_version"
    
    return 0
}

# Main
install_docker "$@"
