#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Create OpenShell sandbox with volume mounts

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/../config"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Default settings
readonly DEFAULT_SANDBOX_NAME="my-assistant"
readonly OPENCLAW_IMAGE="ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest"
readonly GATEWAY_PORT=18789

# Provider settings (inherited from environment)
PROVIDER="${PROVIDER:-nvidia}"

# Provider-specific configurations
declare -A PROVIDER_BASE_URLS=(
    ["nvidia"]="https://integrate.api.nvidia.com/v1"
    ["openai"]="https://api.openai.com/v1"
    ["anthropic"]="https://api.anthropic.com/v1"
    ["openrouter"]="https://openrouter.ai/api/v1"
)

# Create sandbox
create_sandbox() {
    local project_dir="${1:-.}"
    local sandbox_name="${2:-$DEFAULT_SANDBOX_NAME}"

    ui_stage "Creating OpenClaw Sandbox"

    # Ensure openshell is available
    if ! command_exists openshell; then
        ui_error "OpenShell not found. Run the OpenShell installation script first."
        return 1
    fi

    # Ensure Docker is running
    if ! is_docker_running; then
        ui_error "Docker is not running. Please start Docker and retry."
        return 1
    fi

    # Setup directories
    local openclaw_data="${project_dir}/openclaw-data"
    local openclaw_config="${openclaw_data}/.openclaw"
    local openclaw_workspace="${openclaw_data}/workspace"

    ui_info "Setting up persistent data directories..."

    ensure_dir "$openclaw_config"
    ensure_dir "$openclaw_config/agents/main/agent"
    ensure_dir "$openclaw_config/credentials"
    ensure_dir "$openclaw_workspace/skills"

    ui_kv "Data Dir" "$openclaw_data"
    ui_kv "Config" "$openclaw_config"
    ui_kv "Workspace" "$openclaw_workspace"

    # Get default model for provider
    local default_model
    default_model=$(get_provider_config "$PROVIDER" "default_model")

    # Create initial config if not exists
    local config_file="${openclaw_config}/openclaw.json"
    if [[ ! -f "$config_file" ]]; then
        ui_info "Creating initial OpenClaw configuration..."

        local config_template="${CONFIG_DIR}/openclaw.json.template"
        if [[ -f "$config_template" ]]; then
            # Replace placeholder model with provider default
            sed "s|nvidia/nemotron-3-super-120b-a12b|${default_model}|g" \
                "$config_template" > "$config_file"
        else
            # Create minimal config with provider default model
            cat > "$config_file" << JSONEOF
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "${default_model}"
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "${PROVIDER}": {
        "baseUrl": "${PROVIDER_BASE_URLS[$PROVIDER]}",
        "apiKey": "openshell-managed",
        "api": "openai-completions",
        "models": [
          {
            "id": "${default_model}",
            "name": "${default_model}",
            "contextWindow": 128000,
            "maxTokens": 4096
          }
        ]
      }
    }
  },
  "gateway": {
    "mode": "local",
    "controlUi": {
      "allowInsecureAuth": true,
      "dangerouslyDisableDeviceAuth": true,
      "allowedOrigins": ["http://127.0.0.1:18789"]
    }
  }
}
JSONEOF
        fi

        chmod 600 "$config_file"
        ui_success "Created initial configuration for ${PROVIDER}"
    fi

    # Check for existing sandbox
    local existing_sandbox
    existing_sandbox=$(openshell sandbox list 2>/dev/null | grep -E "^${sandbox_name}\\s" || true)

    if [[ -n "$existing_sandbox" ]]; then
        ui_warn "Sandbox '${sandbox_name}' already exists"

        if is_interactive; then
            if ui_confirm "Delete and recreate?"; then
                ui_info "Removing existing sandbox..."
                openshell sandbox delete "$sandbox_name" 2>/dev/null || true
            else
                ui_info "Keeping existing sandbox"
                ui_info "To connect: nemoclaw ${sandbox_name} connect"
                return 0
            fi
        else
            ui_info "Keeping existing sandbox"
            return 0
        fi
    fi

    # Create sandbox with volume mounts
    ui_info "Creating sandbox '${sandbox_name}'..."

    local create_args=(
        "sandbox" "create"
        "--from" "$OPENCLAW_IMAGE"
        "--name" "$sandbox_name"
        "--volume" "${openclaw_config}:/sandbox/.openclaw"
        "--volume" "${openclaw_workspace}:/sandbox/workspace"
        "--forward" "$GATEWAY_PORT"
    )

    local create_log
    create_log=$(create_temp_file)

    if ! ui_run_spinner "Creating sandbox with volume mounts" \
        openshell "${create_args[@]}" \
        > "$create_log" 2>&1; then

        if grep -q "already exists" "$create_log" 2>/dev/null; then
            ui_info "Sandbox already exists, reusing"
        else
            ui_error "Failed to create sandbox"
            if [[ -s "$create_log" ]]; then
                tail -n 20 "$create_log" >&2
            fi
            rm -f "$create_log"
            return 1
        fi
    fi

    rm -f "$create_log"

    ui_success "Sandbox '${sandbox_name}' created"
    ui_kv "Image" "$OPENCLAW_IMAGE"
    ui_kv "Port" "$GATEWAY_PORT"

    # Configure inference
    configure_inference "$sandbox_name" "$project_dir"

    return $?
}

# Configure inference routing
configure_inference() {
    local sandbox_name="$1"
    local project_dir="$2"

    local display_name
    display_name=$(get_provider_display_name "$PROVIDER")
    
    ui_info "Configuring ${display_name} inference routing..."

    # Get environment variable name for provider
    local env_var
    env_var=$(get_provider_config "$PROVIDER" "env_var")

    # Check for API key
    local api_key="${!env_var:-}"

    if [[ -z "$api_key" ]]; then
        local env_file="${project_dir}/config/.env"
        if [[ -f "$env_file" ]]; then
            api_key=$(grep "^${env_var}=" "$env_file" 2>/dev/null | cut -d= -f2- || true)
        fi
    fi

    if [[ -z "$api_key" ]]; then
        ui_warn "No ${display_name} API key found"
        ui_info "Configure manually with:"
        echo ""
        echo " openshell provider create --name ${PROVIDER}-inference --type openai \\"
        echo "   --credential ${env_var}=your-key \\"
        echo "   --config OPENAI_BASE_URL=${PROVIDER_BASE_URLS[$PROVIDER]}"
        echo ""
        local default_model
        default_model=$(get_provider_config "$PROVIDER" "default_model")
        echo " openshell inference set --provider ${PROVIDER}-inference --model ${default_model}"
        return 0
    fi

    # Create provider
    ui_info "Creating ${display_name} inference provider..."

    local provider_log
    provider_log=$(create_temp_file)

    local default_model
    default_model=$(get_provider_config "$PROVIDER" "default_model")

    openshell provider create \
        --name "${PROVIDER}-inference" \
        --type openai \
        --credential "${env_var}=${api_key}" \
        --config "OPENAI_BASE_URL=${PROVIDER_BASE_URLS[$PROVIDER]}" \
        > "$provider_log" 2>&1 || true

    if grep -q "already exists" "$provider_log" 2>/dev/null; then
        ui_info "Provider already exists, updating..."
        openshell provider update "${PROVIDER}-inference" \
            --credential "${env_var}=${api_key}" \
            > /dev/null 2>&1 || true
    fi

    rm -f "$provider_log"

    # Set inference route
    ui_info "Setting inference route..."
    openshell inference set \
        --provider "${PROVIDER}-inference" \
        --model "${default_model}" \
        > /dev/null 2>&1 || true

    ui_success "Inference configured for ${display_name}"

    return 0
}

# Main
create_sandbox "$@"
