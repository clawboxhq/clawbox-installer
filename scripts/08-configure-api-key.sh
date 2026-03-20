#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Configure LLM provider API key interactively

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/../config"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Provider selection (can be overridden via environment)
PROVIDER="${PROVIDER:-}"

# Select provider interactively
select_provider() {
    ui_stage "Select LLM Provider"
    
    echo ""
    ui_info "Available providers:"
    echo ""
    
    local providers
    providers=$(get_providers)
    local i=1
    
    for p in $providers; do
        local display_name
        display_name=$(get_provider_display_name "$p")
        local default_model
        default_model=$(get_provider_config "$p" "default_model")
        printf "  ${GREEN}%d${NC}) ${BOLD}%s${NC} - %s\n" "$i" "$display_name" "$default_model"
        ((i++))
    done
    
    echo ""
    ui_info "Default: NVIDIA (NIM API)"
    echo ""
    
    local choice
    read -rp "$(ui_prompt "Select provider [1-4] (default: 1)") " choice
    
    case "${choice:-1}" in
        1) echo "nvidia" ;;
        2) echo "openai" ;;
        3) echo "anthropic" ;;
        4) echo "openrouter" ;;
        *)
            ui_warn "Invalid choice, defaulting to NVIDIA"
            echo "nvidia"
            ;;
    esac
}

# Configure API key for a specific provider
configure_provider_api_key() {
    local provider="$1"
    local project_dir="${2:-.}"
    local env_file="${project_dir}/config/.env"
    
    local display_name
    display_name=$(get_provider_display_name "$provider")
    
    ui_stage "Configuring ${display_name} API Key"
    
    local env_var
    env_var=$(get_provider_config "$provider" "env_var")
    local key_url
    key_url=$(get_provider_config "$provider" "url")
    local default_model
    default_model=$(get_provider_config "$provider" "default_model")
    
    # Check for existing API key
    local existing_key=""
    if [[ -f "$env_file" ]]; then
        existing_key=$(grep "^${env_var}=" "$env_file" 2>/dev/null | cut -d= -f2- || true)
    fi
    
    # Also check environment
    if [[ -z "$existing_key" && -n "${!env_var:-}" ]]; then
        existing_key="${!env_var}"
        ui_info "Found ${env_var} in environment"
    fi
    
    if [[ -n "$existing_key" ]]; then
        local masked
        masked=$(mask_sensitive "$existing_key")
        ui_info "Existing API key found: $masked"
        
        if is_interactive; then
            if ui_confirm "Use existing key?"; then
                ui_success "Using existing API key"
                export "$env_var"="$existing_key"
                return 0
            fi
        else
            ui_success "Using existing API key"
            export "$env_var"="$existing_key"
            return 0
        fi
    fi
    
    # Prompt for new key
    if ! is_interactive; then
        ui_error "No API key found for ${display_name} and non-interactive mode"
        ui_info "Set ${env_var} environment variable or run interactively"
        return 1
    fi
    
    echo ""
    ui_info "Get your ${display_name} API key from:"
    ui_kv "URL" "$key_url"
    ui_kv "Default Model" "$default_model"
    echo ""
    
    local api_key
    api_key=$(ui_prompt_password "Enter your ${display_name} API key")
    
    if [[ -z "$api_key" ]]; then
        ui_error "No API key provided"
        return 1
    fi
    
    # Validate format
    if ! validate_provider_api_key "$provider" "$api_key"; then
        ui_error "Invalid API key format for ${display_name}"
        local expected_prefix
        expected_prefix=$(get_provider_config "$provider" "key_prefix")
        ui_info "Expected prefix: ${expected_prefix}"
        return 1
    fi
    
    # Validate with API (for providers that support it)
    validate_api_key_online "$provider" "$api_key"
    
    # Save to env file
    ensure_dir "$(dirname "$env_file")"
    
    # Check if file exists
    if [[ -f "$env_file" ]]; then
        # Update existing key
        if grep -q "^${env_var}=" "$env_file"; then
            if [[ "$(uname -s)" == "Darwin" ]]; then
                sed -i '' "s|^${env_var}=.*|${env_var}=${api_key}|" "$env_file"
            else
                sed -i "s|^${env_var}=.*|${env_var}=${api_key}|" "$env_file"
            fi
        else
            echo "${env_var}=${api_key}" >> "$env_file"
        fi
    else
        echo "${env_var}=${api_key}" > "$env_file"
        chmod 600 "$env_file"
    fi
    
    ui_success "API key saved to $env_file"
    
    # Export for current session
    export "$env_var"="$api_key"
    
    return 0
}

# Validate API key with online request
validate_api_key_online() {
    local provider="$1"
    local api_key="$2"
    
    ui_info "Validating API key..."
    
    local validation_url
    validation_url=$(get_provider_config "$provider" "validation_url")
    
    case "$provider" in
        nvidia)
            local response
            response=$(curl -sS -w "\n%{http_code}" \
                -H "Authorization: Bearer $api_key" \
                -H "Content-Type: application/json" \
                "$validation_url" 2>/dev/null || echo -e "\n000")
            
            local http_code
            http_code=$(echo "$response" | tail -1)
            
            if [[ "$http_code" == "200" ]]; then
                ui_success "API key validated successfully"
            else
                ui_warn "Could not validate API key (HTTP $http_code)"
                ui_info "Continuing anyway - you can verify later"
            fi
            ;;
        openai)
            local response
            response=$(curl -sS -w "\n%{http_code}" \
                -H "Authorization: Bearer $api_key" \
                "$validation_url" 2>/dev/null || echo -e "\n000")
            
            local http_code
            http_code=$(echo "$response" | tail -1)
            
            if [[ "$http_code" == "200" ]]; then
                ui_success "API key validated successfully"
            else
                ui_warn "Could not validate API key (HTTP $http_code)"
                ui_info "Continuing anyway - you can verify later"
            fi
            ;;
        anthropic|openrouter)
            ui_info "Skipping online validation for ${provider}"
            ui_info "Key format validated successfully"
            ;;
        *)
            ui_info "Skipping online validation for unknown provider"
            ;;
    esac
}

# Configure API key (main entry point)
configure_api_key() {
    local project_dir="${1:-.}"
    
    # If provider not set, prompt for selection
    if [[ -z "$PROVIDER" ]]; then
        if is_interactive; then
            PROVIDER=$(select_provider)
        else
            # Default to NVIDIA in non-interactive mode
            PROVIDER="nvidia"
            ui_info "No provider specified, defaulting to NVIDIA"
        fi
    fi
    
    # Validate provider
    if [[ -z "${PROVIDER_CONFIG[$PROVIDER]:-}" ]]; then
        ui_error "Unknown provider: $PROVIDER"
        ui_info "Valid providers: $(get_providers | tr '\n' ' ')"
        return 1
    fi
    
    configure_provider_api_key "$PROVIDER" "$project_dir"
}

# Main
configure_api_key "$@"
