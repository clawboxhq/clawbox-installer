#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Configure NVIDIA API key interactively

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/../config"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Configure API key
configure_api_key() {
    local project_dir="${1:-.}"
    local env_file="${project_dir}/config/.env"
    
    ui_stage "Configuring NVIDIA API Key"
    
    # Check for existing API key
    local existing_key=""
    if [[ -f "$env_file" ]]; then
        existing_key=$(grep "^NVIDIA_API_KEY=" "$env_file" 2>/dev/null | cut -d= -f2- || true)
    fi
    
    # Also check environment
    if [[ -z "$existing_key" && -n "${NVIDIA_API_KEY:-}" ]]; then
        existing_key="$NVIDIA_API_KEY"
        ui_info "Found NVIDIA_API_KEY in environment"
    fi
    
    if [[ -n "$existing_key" ]]; then
        local masked
        masked=$(mask_sensitive "$existing_key")
        ui_info "Existing API key found: $masked"
        
        if is_interactive; then
            if ui_confirm "Use existing key?"; then
                ui_success "Using existing API key"
                return 0
            fi
        else
            ui_success "Using existing API key"
            return 0
        fi
    fi
    
    # Prompt for new key
    if ! is_interactive; then
        ui_error "No API key found and non-interactive mode"
        ui_info "Set NVIDIA_API_KEY environment variable or run interactively"
        return 1
    fi
    
    echo ""
    ui_info "Get your NVIDIA API key from:"
    ui_kv "URL" "https://build.nvidia.com/settings/api-keys"
    echo ""
    
    local api_key
    api_key=$(ui_prompt_password "Enter your NVIDIA API key")
    
    if [[ -z "$api_key" ]]; then
        ui_error "No API key provided"
        return 1
    fi
    
    # Validate format
    if ! validate_api_key "$api_key"; then
        ui_error "Invalid API key format"
        return 1
    fi
    
    # Validate with API
    ui_info "Validating API key..."
    
    local validation_response
    validation_response=$(curl -sS -w "\n%{http_code}" \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        "https://integrate.api.nvidia.com/v1/models" 2>/dev/null || echo -e "\n000")
    
    local http_code
    http_code=$(echo "$validation_response" | tail -1)
    
    if [[ "$http_code" == "200" ]]; then
        ui_success "API key validated successfully"
    else
        ui_warn "Could not validate API key (HTTP $http_code)"
        ui_info "Continuing anyway - you can verify later"
    fi
    
    # Save to env file
    ensure_dir "$(dirname "$env_file")"
    
    # Check if file exists
    if [[ -f "$env_file" ]]; then
        # Update existing key
        if grep -q "^NVIDIA_API_KEY=" "$env_file"; then
            # Use sed to replace
            if [[ "$(uname -s)" == "Darwin" ]]; then
                sed -i '' "s|^NVIDIA_API_KEY=.*|NVIDIA_API_KEY=${api_key}|" "$env_file"
            else
                sed -i "s|^NVIDIA_API_KEY=.*|NVIDIA_API_KEY=${api_key}|" "$env_file"
            fi
        else
            echo "NVIDIA_API_KEY=${api_key}" >> "$env_file"
        fi
    else
        echo "NVIDIA_API_KEY=${api_key}" > "$env_file"
        chmod 600 "$env_file"
    fi
    
    ui_success "API key saved to $env_file"
    
    # Export for current session
    export NVIDIA_API_KEY="$api_key"
    
    return 0
}

# Main
configure_api_key "$@"
