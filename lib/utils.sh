#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Common utility functions for ClawBox installer

# Prevent multiple sourcing
[[ -n "${_CLAWBOX_UTILS_LOADED:-}" ]] && return 0
readonly _CLAWBOX_UTILS_LOADED=1

# Source colors if not already loaded
if [[ -z "${NC:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Version requirements
MIN_NODE_MAJOR=22
MIN_NPM_MAJOR=10
MIN_DOCKER_VERSION="28.04"
MIN_MACOS_VERSION="14.0"

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin) echo "macos" ;;
        Linux)  echo "linux" ;;
        *)      echo "unsupported" ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)             echo "unknown" ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Check if running as root
is_root() {
    [[ "$(id -u)" -eq 0 ]]
}

# Get current user
get_current_user() {
    whoami
}

# Compare two semver strings (major.minor.patch)
# Returns 0 if $1 >= $2
version_gte() {
    local IFS=.
    local -a a=($1) b=($2)
    for i in 0 1 2; do
        local ai=${a[$i]:-0} bi=${b[$i]:-0}
        if (( ai > bi )); then return 0; fi
        if (( ai < bi )); then return 1; fi
    done
    return 0
}

# Extract major version from version string
version_major() {
    echo "${1#v}" | cut -d. -f1
}

# Check if macOS version meets minimum requirement
check_macos_version() {
    local current
    current=$(sw_vers -productVersion 2>/dev/null || echo "0.0.0")
    
    if version_gte "$current" "$MIN_MACOS_VERSION"; then
        return 0
    else
        return 1
    fi
}

# Get total RAM in GB
get_total_ram_gb() {
    local bytes
    bytes=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    echo $(( bytes / 1024 / 1024 / 1024 ))
}

# Get available disk space in GB for a path
get_available_disk_gb() {
    local path="${1:-/}"
    local kb
    kb=$(df -k "$path" 2>/dev/null | tail -1 | awk '{print $4}')
    echo $(( kb / 1024 / 1024 ))
}

# Get Node.js major version
get_node_major_version() {
    if ! command_exists node; then
        echo "0"
        return
    fi
    local version
    version=$(node -v 2>/dev/null || echo "v0.0.0")
    version_major "$version"
}

# Get npm major version
get_npm_major_version() {
    if ! command_exists npm; then
        echo "0"
        return
    fi
    local version
    version=$(npm -v 2>/dev/null || echo "0.0.0")
    version_major "$version"
}

# Get Docker version
get_docker_version() {
    if ! command_exists docker; then
        echo ""
        return
    fi
    docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1
}

# Check if Docker daemon is running
is_docker_running() {
    docker info &>/dev/null
}

# Wait for Docker daemon to be ready
wait_for_docker() {
    local timeout="${1:-60}"
    local count=0
    
    while ! is_docker_running; do
        if (( count >= timeout )); then
            return 1
        fi
        sleep 1
        ((count++))
    done
    return 0
}

# Resolve Homebrew binary path
resolve_brew_bin() {
    local brew_bin=""
    brew_bin=$(command -v brew 2>/dev/null || true)
    
    if [[ -n "$brew_bin" ]]; then
        echo "$brew_bin"
        return 0
    fi
    
    if [[ -x "/opt/homebrew/bin/brew" ]]; then
        echo "/opt/homebrew/bin/brew"
        return 0
    fi
    
    if [[ -x "/usr/local/bin/brew" ]]; then
        echo "/usr/local/bin/brew"
        return 0
    fi
    
    return 1
}

# Activate Homebrew for current session
activate_brew_for_session() {
    local brew_bin
    brew_bin=$(resolve_brew_bin || true)
    
    if [[ -z "$brew_bin" ]]; then
        return 1
    fi
    
    if [[ -z "$(command -v brew 2>/dev/null || true)" ]]; then
        eval "$("$brew_bin" shellenv)"
    fi
    return 0
}

# Download a file using curl or wget
download_file() {
    local url="$1"
    local output="$2"
    
    if command_exists curl; then
        curl -fsSL --proto '=https' --tlsv1.2 --retry 3 --retry-delay 1 -o "$output" "$url"
    elif command_exists wget; then
        wget -q --https-only --secure-protocol=TLSv1_2 --tries=3 -O "$output" "$url"
    else
        return 1
    fi
}

# Create a temporary file
create_temp_file() {
    mktemp
}

# Create a temporary directory
create_temp_dir() {
    mktemp -d
}

# Cleanup temporary files
cleanup_temp() {
    local -a files=("$@")
    for f in "${files[@]}"; do
        rm -rf "$f" 2>/dev/null || true
    done
}

# Ensure a directory exists
ensure_dir() {
    local dir="$1"
    mkdir -p "$dir"
}

# Get shell profile path
get_shell_profile() {
    local shell_name
    shell_name=$(basename "${SHELL:-sh}")
    
    case "$shell_name" in
        zsh)  echo "$HOME/.zshrc" ;;
        bash) 
            if [[ -f "$HOME/.bashrc" ]]; then
                echo "$HOME/.bashrc"
            else
                echo "$HOME/.profile"
            fi
            ;;
        fish) echo "$HOME/.config/fish/config.fish" ;;
        *)    echo "$HOME/.profile" ;;
    esac
}

# Check if a line exists in a file
line_in_file() {
    local file="$1"
    local line="$2"
    grep -qF "$line" "$file" 2>/dev/null
}

# Add line to file if not present
add_to_file() {
    local file="$1"
    local line="$2"
    
    if [[ ! -f "$file" ]]; then
        echo "$line" > "$file"
        return
    fi
    
    if ! line_in_file "$file" "$line"; then
        echo "$line" >> "$file"
    fi
}

# Mask a sensitive value (like API key) for display
mask_sensitive() {
    local value="$1"
    local len=${#value}
    
    if (( len <= 8 )); then
        echo "********"
    else
        echo "${value:0:4}...${value: -4}"
    fi
}

# Validate API key format
validate_api_key() {
    local key="$1"
    local len=${#key}

    # Basic validation: non-empty, reasonable length
    if [[ -z "$key" ]] || (( len < 8 )); then
        return 1
    fi

    return 0
}

# Provider configuration
declare -A PROVIDER_CONFIG=(
    ["nvidia"]="NVIDIA_API_KEY|nvapi-|https://build.nvidia.com/settings/api-keys|https://integrate.api.nvidia.com/v1/models|nvidia/nemotron-3-super-120b-a12b"
    ["openai"]="OPENAI_API_KEY|sk-|https://platform.openai.com/api-keys|https://api.openai.com/v1/models|gpt-4o"
    ["anthropic"]="ANTHROPIC_API_KEY|sk-ant-|https://console.anthropic.com/settings/keys|https://api.anthropic.com/v1/messages|claude-sonnet-4-20250514"
    ["openrouter"]="OPENROUTER_API_KEY|sk-or-|https://openrouter.ai/keys|https://openrouter.ai/api/v1/models|anthropic/claude-sonnet-4"
)

# Get provider names
get_providers() {
    echo "${!PROVIDER_CONFIG[@]}" | tr ' ' '\n' | sort
}

# Get provider config value by key
# Usage: get_provider_config "nvidia" "env_var" -> "NVIDIA_API_KEY"
get_provider_config() {
    local provider="$1"
    local field="$2"
    local config="${PROVIDER_CONFIG[$provider]:-}"
    
    if [[ -z "$config" ]]; then
        return 1
    fi
    
    local env_var key_prefix url validation_url default_model
    IFS='|' read -r env_var key_prefix url validation_url default_model <<< "$config"
    
    case "$field" in
        env_var) echo "$env_var" ;;
        key_prefix) echo "$key_prefix" ;;
        url) echo "$url" ;;
        validation_url) echo "$validation_url" ;;
        default_model) echo "$default_model" ;;
        *) return 1 ;;
    esac
}

# Validate API key against provider
validate_provider_api_key() {
    local provider="$1"
    local key="$2"
    
    # First, basic validation
    if ! validate_api_key "$key"; then
        return 1
    fi
    
    # Provider-specific prefix validation
    local prefix
    prefix=$(get_provider_config "$provider" "key_prefix")
    
    case "$provider" in
        nvidia)
            [[ "$key" == nvapi-* ]]
            ;;
        openai)
            [[ "$key" == sk-* ]]
            ;;
        anthropic)
            [[ "$key" == sk-ant-* ]]
            ;;
        openrouter)
            [[ "$key" == sk-or-* ]]
            ;;
        *)
            # Unknown provider, accept any key
            return 0
            ;;
    esac
}

# Get provider display name
get_provider_display_name() {
    local provider="$1"
    case "$provider" in
        nvidia) echo "NVIDIA (NIM API)" ;;
        openai) echo "OpenAI" ;;
        anthropic) echo "Anthropic" ;;
        openrouter) echo "OpenRouter" ;;
        *) echo "$provider" ;;
    esac
}

# Get project root directory
get_project_root() {
    local script_dir
    script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
    dirname "$script_dir"
}

# Check if running in interactive mode
is_interactive() {
    if [[ "${NO_PROMPT:-0}" == "1" ]]; then
        return 1
    fi
    [[ -t 0 && -t 1 ]]
}
