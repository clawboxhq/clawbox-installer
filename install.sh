#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# ClawBox - Secure AI Assistant in a Box
# One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw
#
# Usage:
#   curl -fsSL https://clawboxhq.github.io/clawbox-installer/install.sh | bash
#   ./install.sh [options]
#
# Options:
#   --non-interactive    Run without prompts (requires PROVIDER_API_KEY env)
#   --provider PROVIDER  LLM provider (nvidia, openai, anthropic, openrouter)
#   --skip-docker        Skip Docker installation (use existing)
#   --skip-node          Skip Node.js installation (use existing)
#   --sandbox-name       Custom sandbox name (default: my-assistant)
#   --dry-run            Show what would be installed
#   --help               Show this help message

set -euo pipefail

# Version
readonly INSTALLER_VERSION="0.1.0"
readonly PROJECT_NAME="ClawBox"
readonly PROJECT_TAGLINE="Secure AI Assistant in a Box"

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"
CONFIG_DIR="${SCRIPT_DIR}/config"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Default options
NON_INTERACTIVE="${NON_INTERACTIVE:-0}"
SKIP_DOCKER="${SKIP_DOCKER:-0}"
SKIP_NODE="${SKIP_NODE:-0}"
DRY_RUN="${DRY_RUN:-0}"
SANDBOX_NAME="${SANDBOX_NAME:-my-assistant}"
NO_PROMPT="${NO_PROMPT:-0}"
PROVIDER="${PROVIDER:-nvidia}"

# Print usage
usage() {
    cat << EOF
${PROJECT_NAME} v${INSTALLER_VERSION}
${PROJECT_TAGLINE}

One-click cross-platform installer for OpenShell + NemoClaw + OpenClaw
with secure sandboxing and persistent volume mounting.

Usage:
  curl -fsSL https://clawboxhq.github.io/clawbox-installer/install.sh | bash
  ./install.sh [options]

Options:
  --non-interactive    Run without prompts (requires PROVIDER_API_KEY env)
  --provider PROVIDER  LLM provider: nvidia, openai, anthropic, openrouter
                       (default: nvidia)
  --skip-docker        Skip Docker installation (use existing)
  --skip-node          Skip Node.js installation (use existing)
  --sandbox-name NAME  Custom sandbox name (default: my-assistant)
  --project-dir DIR    Project directory (default: script location)
  --dry-run            Show what would be installed
  --verbose            Enable verbose output
  --help               Show this help message

Environment Variables:
  PROVIDER              LLM provider (nvidia, openai, anthropic, openrouter)
  NVIDIA_API_KEY        API key for NVIDIA NIM API (when provider=nvidia)
  OPENAI_API_KEY        API key for OpenAI (when provider=openai)
  ANTHROPIC_API_KEY     API key for Anthropic (when provider=anthropic)
  OPENROUTER_API_KEY    API key for OpenRouter (when provider=openrouter)
  NON_INTERACTIVE       Set to 1 for non-interactive mode
  SKIP_DOCKER           Set to 1 to skip Docker installation
  SKIP_NODE             Set to 1 to skip Node.js installation
  SANDBOX_NAME          Sandbox name override

Providers:
  nvidia      NVIDIA NIM API (default)
              Models: nemotron-3-super-120b-a12b, etc.
              Get key: https://build.nvidia.com/settings/api-keys

  openai      OpenAI API
              Models: gpt-4o, gpt-4-turbo, gpt-3.5-turbo
              Get key: https://platform.openai.com/api-keys

  anthropic   Anthropic API
              Models: claude-sonnet-4-20250514, claude-3-opus, etc.
              Get key: https://console.anthropic.com/settings/keys

  openrouter  OpenRouter API (multi-provider gateway)
              Models: All major LLMs via single API
              Get key: https://openrouter.ai/keys

Examples:
  # Interactive installation (prompts for provider selection)
  ./install.sh

  # Non-interactive with NVIDIA
  PROVIDER=nvidia NVIDIA_API_KEY=nvapi-xxx ./install.sh --non-interactive

  # Non-interactive with OpenAI
  PROVIDER=openai OPENAI_API_KEY=sk-xxx ./install.sh --non-interactive

  # Non-interactive with Anthropic
  PROVIDER=anthropic ANTHROPIC_API_KEY=sk-ant-xxx ./install.sh --non-interactive

  # Using --provider flag
  ./install.sh --provider openai --non-interactive

  # Custom sandbox name
  ./install.sh --sandbox-name my-ai-assistant

  # Dry run to see installation plan
  ./install.sh --dry-run

For more information: https://github.com/clawboxhq/clawbox-installer
EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive)
                NON_INTERACTIVE=1
                NO_PROMPT=1
                shift
                ;;
            --provider)
                PROVIDER="$2"
                shift 2
                ;;
            --skip-docker)
                SKIP_DOCKER=1
                shift
                ;;
            --skip-node)
                SKIP_NODE=1
                shift
                ;;
            --sandbox-name)
                SANDBOX_NAME="$2"
                shift 2
                ;;
            --project-dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            --verbose)
                VERBOSE=1
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                ui_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Validate provider
    if [[ -z "${PROVIDER_CONFIG[$PROVIDER]:-}" ]]; then
        ui_error "Unknown provider: $PROVIDER"
        ui_info "Valid providers: $(get_providers | tr '\n' ' ')"
        exit 1
    fi
}

# Show installation plan
show_plan() {
    local project_dir="$1"
    
    local display_name default_model
    display_name=$(get_provider_display_name "$PROVIDER")
    default_model=$(get_provider_config "$PROVIDER" "default_model")

    ui_section "Installation Plan"

    ui_kv "Platform" "$(detect_os) ($(detect_arch))"
    ui_kv "Provider" "${display_name}"
    ui_kv "Default Model" "${default_model}"
    ui_kv "Project Dir" "$project_dir"
    ui_kv "Data Dir" "${project_dir}/openclaw-data"
    ui_kv "Sandbox Name" "$SANDBOX_NAME"
    ui_kv "Sandbox Image" "ghcr.io/nvidia/openshell-community/sandboxes/openclaw:latest"
    ui_kv "Gateway Port" "18789"

    echo ""
    ui_info "Installation steps:"
    echo "  1. Check system architecture"
    echo "  2. Check prerequisites (RAM, disk, network)"
    echo "  3. Install Homebrew (if not present)"
    echo "  4. Install Node.js 22+ (if not present)"
    echo "  5. Install Docker Desktop (if not present)"
    echo "  6. Install OpenShell CLI"
    echo "  7. Install NemoClaw"
    echo "  8. Configure ${display_name} API key"
    echo "  9. Create sandbox with volume mounts"
    echo " 10. Verify installation"

    if [[ "$SKIP_DOCKER" == "1" ]]; then
        ui_info "Skipping: Docker installation"
    fi

    if [[ "$SKIP_NODE" == "1" ]]; then
        ui_info "Skipping: Node.js installation"
    fi

    if [[ "$DRY_RUN" == "1" ]]; then
        ui_warn "Dry run mode - no changes will be made"
    fi

    echo ""
}

# Run installation step
run_step() {
    local step_num="$1"
    local step_name="$2"
    local script="$3"
    shift 3
    local args=("$@")
    
    if [[ "$DRY_RUN" == "1" ]]; then
        ui_info "[Step ${step_num}] Would run: ${step_name}"
        return 0
    fi
    
    ui_info "[Step ${step_num}] ${step_name}"
    
    if [[ -x "$script" ]]; then
        if ! "$script" "${args[@]}"; then
            ui_error "Step ${step_num} failed: ${step_name}"
            return 1
        fi
    else
        ui_error "Script not found: $script"
        return 1
    fi
    
    return 0
}

# Main installation
main() {
    # Parse command line arguments
    parse_args "$@"

    # Set project directory
    PROJECT_DIR="${PROJECT_DIR:-$SCRIPT_DIR}"

    # Show banner
    ui_banner "$INSTALLER_VERSION"
    
    # Export provider for subprocess scripts
    export PROVIDER

    # Show plan
    show_plan "$PROJECT_DIR"
    
    # Confirm installation
    if [[ "$NON_INTERACTIVE" != "1" && "$DRY_RUN" != "1" ]]; then
        if is_interactive; then
            if ! ui_confirm "Proceed with installation?"; then
                ui_info "Installation cancelled"
                exit 0
            fi
        fi
    fi
    
    # Exit early for dry run
    if [[ "$DRY_RUN" == "1" ]]; then
        ui_success "Dry run complete"
        exit 0
    fi
    
    # Track start time
    local start_time
    start_time=$(date +%s)
    
    # Run installation steps
    local step=0
    local errors=0
    
    # Step 1: Check architecture
    ((step++))
    if ! run_step $step "Checking architecture" "${SCRIPTS_DIR}/01-check-architecture.sh"; then
        ((errors++))
    fi
    
    # Step 2: Check prerequisites
    ((step++))
    if ! run_step $step "Checking prerequisites" "${SCRIPTS_DIR}/02-check-prerequisites.sh"; then
        ((errors++))
    fi
    
    # Step 3: Install Homebrew
    ((step++))
    if ! run_step $step "Installing Homebrew" "${SCRIPTS_DIR}/03-install-homebrew.sh"; then
        ((errors++))
    fi
    
    # Step 4: Install Node.js
    if [[ "$SKIP_NODE" != "1" ]]; then
        ((step++))
        if ! run_step $step "Installing Node.js" "${SCRIPTS_DIR}/04-install-nodejs.sh"; then
            ((errors++))
        fi
    fi
    
    # Step 5: Install Docker
    if [[ "$SKIP_DOCKER" != "1" ]]; then
        ((step++))
        if ! run_step $step "Installing Docker" "${SCRIPTS_DIR}/05-install-docker.sh"; then
            ((errors++))
        fi
    else
        # Verify Docker is running if skipped
        if ! is_docker_running; then
            ui_error "Docker is not running but Docker installation was skipped"
            ((errors++))
        fi
    fi
    
    # Step 6: Install OpenShell
    ((step++))
    if ! run_step $step "Installing OpenShell" "${SCRIPTS_DIR}/06-install-openshell.sh"; then
        ((errors++))
    fi
    
    # Step 7: Install NemoClaw
    ((step++))
    if ! run_step $step "Installing NemoClaw" "${SCRIPTS_DIR}/07-install-nemoclaw.sh"; then
        ((errors++))
    fi
    
    # Step 8: Configure API key
    ((step++))
    if ! run_step $step "Configuring API key" "${SCRIPTS_DIR}/08-configure-api-key.sh" "$PROJECT_DIR"; then
        ui_warn "API key configuration failed - configure manually later"
    fi
    
    # Step 9: Create sandbox
    ((step++))
    if ! run_step $step "Creating sandbox" "${SCRIPTS_DIR}/09-create-sandbox.sh" "$PROJECT_DIR" "$SANDBOX_NAME"; then
        ((errors++))
    fi
    
    # Step 10: Verify installation
    ((step++))
    if ! run_step $step "Verifying installation" "${SCRIPTS_DIR}/10-verify-installation.sh" "$PROJECT_DIR" "$SANDBOX_NAME"; then
        ui_warn "Some verification checks failed"
    fi
    
    # Calculate duration
    local end_time duration
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    
    # Show result
    echo ""
    
    if (( errors > 0 )); then
        ui_error "Installation completed with $errors error(s)"
        ui_info "Check the output above for details"
        exit 1
    fi
    
    # Show completion banner
    ui_complete "$SANDBOX_NAME" "$PROJECT_DIR"
    
    # Show next steps
    echo ""
    ui_section "Next Steps"
    echo ""
    echo "  1. Connect to your sandbox:"
    echo "     ${CYAN}nemoclaw ${SANDBOX_NAME} connect${NC}"
    echo ""
    echo "  2. Inside the sandbox, use OpenClaw:"
    echo "     ${CYAN}openclaw tui${NC}              # Launch terminal UI"
    echo "     ${CYAN}openclaw agent -m 'hello'${NC}  # Send a test message"
    echo ""
    echo "  3. Monitor network activity:"
    echo "     ${CYAN}openshell term${NC}             # Launch monitoring dashboard"
    echo ""
    echo "  4. Data persistence:"
    echo "     Your OpenClaw data is stored in:"
    echo "     ${MUTED}${PROJECT_DIR}/openclaw-data/${NC}"
    echo ""
    
    # Show duration
    ui_info "Installation completed in ${duration} seconds"
    
    return 0
}

# Run main
main "$@"
