#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# ClawBox Uninstaller
# Removes all ClawBox-installed components and optionally OpenShell

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Parse options
KEEP_OPENSHELL="${KEEP_OPENSHELL:-0}"
DELETE_MODELS="${DELETE_MODELS:-0}"
YES="${YES:-0}"

# Print usage
usage() {
    cat << EOF
ClawBox Uninstaller - Remove ClawBox and installed components

Usage: ./uninstall.sh [options]

Options:
  --yes               Skip confirmation prompt
  --keep-openshell    Leave OpenShell binary installed
  --delete-models     Remove NemoClaw-pulled Ollama models
  --help              Show this help message

Environment Variables:
  KEEP_OPENSHELL      Set to 1 to keep OpenShell
  DELETE_MODELS       Set to 1 to delete Ollama models
  YES                 Set to 1 to skip confirmation

Examples:
  # Interactive uninstall
  ./uninstall.sh

  # Force uninstall without prompts
  ./uninstall.sh --yes

  # Keep OpenShell, uninstall everything else
  ./uninstall.sh --keep-openshell
EOF
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes)
                YES=1
                shift
                ;;
            --keep-openshell)
                KEEP_OPENSHELL=1
                shift
                ;;
            --delete-models)
                DELETE_MODELS=1
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
}

# Stop and remove sandboxes
remove_sandboxes() {
    ui_section "Removing Sandboxes"
    
    local sandboxes
    sandboxes=$(openshell sandbox list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    
    if [[ -z "$sandboxes" ]]; then
        ui_info "No sandboxes found"
        return 0
    fi
    
    for sb in $sandboxes; do
        ui_info "Stopping sandbox: $sb"
        openshell sandbox stop "$sb" 2>/dev/null || true
        
        ui_info "Removing sandbox: $sb"
        openshell sandbox delete "$sb" 2>/dev/null || true
    done
    
    ui_success "All sandboxes removed"
}

# Remove providers
remove_providers() {
    ui_section "Removing Providers"
    
    local providers
    providers=$(openshell provider list 2>/dev/null | awk 'NR>1 {print $1}' || true)
    
    if [[ -z "$providers" ]]; then
        ui_info "No providers found"
        return 0
    fi
    
    for p in $providers; do
        ui_info "Removing provider: $p"
        openshell provider delete "$p" 2>/dev/null || true
    done
    
    ui_success "All providers removed"
}

# Remove NemoClaw
remove_nemoclaw() {
    ui_section "Removing NemoClaw"
    
    if command_exists npm; then
        ui_info "Uninstalling NemoClaw npm package..."
        npm uninstall -g nemoclaw 2>/dev/null || true
    fi
    
    # Remove shim
    local shim_path="$HOME/.local/bin/nemoclaw"
    if [[ -L "$shim_path" || -f "$shim_path" ]]; then
        rm -f "$shim_path"
        ui_info "Removed shim: $shim_path"
    fi
    
    ui_success "NemoClaw removed"
}

# Remove OpenShell
remove_openshell() {
    if [[ "$KEEP_OPENSHELL" == "1" ]]; then
        ui_info "Keeping OpenShell (--keep-openshell)"
        return 0
    fi
    
    ui_section "Removing OpenShell"
    
    # Stop gateway
    ui_info "Stopping OpenShell gateway..."
    openshell gateway stop 2>/dev/null || true
    
    # Remove binary
    local openshell_bin
    openshell_bin=$(command -v openshell 2>/dev/null || echo "$HOME/.local/bin/openshell")
    
    if [[ -f "$openshell_bin" ]]; then
        rm -f "$openshell_bin"
        ui_info "Removed: $openshell_bin"
    fi
    
    # Remove data directory (optional)
    local openshell_data="$HOME/.openshell"
    if [[ -d "$openshell_data" ]]; then
        ui_info "OpenShell data directory preserved: $openshell_data"
        ui_info "To remove: rm -rf $openshell_data"
    fi
    
    ui_success "OpenShell removed"
}

# Remove Ollama models
remove_ollama_models() {
    if [[ "$DELETE_MODELS" != "1" ]]; then
        return 0
    fi
    
    ui_section "Removing Ollama Models"
    
    if ! command_exists ollama; then
        ui_info "Ollama not found"
        return 0
    fi
    
    local models
    models=$(ollama list 2>/dev/null | grep -E "nemotron|nemoclaw" | awk '{print $1}' || true)
    
    for m in $models; do
        ui_info "Removing model: $m"
        ollama rm "$m" 2>/dev/null || true
    done
    
    ui_success "Ollama models removed"
}

# Remove ClawBox data
remove_data() {
    ui_section "Removing Data"
    
    local nemoclaw_data="$HOME/.nemoclaw"
    
    if [[ -d "$nemoclaw_data" ]]; then
        ui_info "Removing: $nemoclaw_data"
        rm -rf "$nemoclaw_data"
    fi
    
    ui_success "Data removed"
}

# Main
main() {
    parse_args "$@"
    
    ui_banner "Uninstaller"
    
    echo ""
    ui_warn "This will remove:"
    echo "  • All OpenShell sandboxes"
    echo "  • All OpenShell providers"
    echo "  • NemoClaw npm package"
    if [[ "$KEEP_OPENSHELL" != "1" ]]; then
        echo "  • OpenShell binary"
    fi
    if [[ "$DELETE_MODELS" == "1" ]]; then
        echo "  • NemoClaw Ollama models"
    fi
    echo "  • ClawBox state data"
    echo ""
    
    if [[ "$YES" != "1" ]]; then
        if ! ui_confirm "Continue with uninstall?"; then
            ui_info "Uninstall cancelled"
            exit 0
        fi
    fi
    
    # Check if openshell is available
    if ! command_exists openshell; then
        ui_warn "OpenShell not found - some steps will be skipped"
    fi
    
    # Remove components
    remove_sandboxes
    remove_providers
    remove_nemoclaw
    remove_openshell
    remove_ollama_models
    remove_data
    
    echo ""
    ui_success "Uninstall complete"
    echo ""
    
    ui_info "The following may still be installed:"
    echo "  • Homebrew (brew)"
    echo "  • Node.js (node, npm)"
    echo "  • Docker Desktop"
    echo "  • OpenClaw host installation (if any)"
    echo ""
    
    if [[ "$KEEP_OPENSHELL" == "1" ]]; then
        ui_info "OpenShell was preserved. To remove:"
        echo "  rm -f \$(command -v openshell)"
        echo ""
    fi
}

main "$@"
