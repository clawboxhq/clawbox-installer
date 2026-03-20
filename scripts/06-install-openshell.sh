#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Install OpenShell binary

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$(dirname "$SCRIPT_DIR")/lib"

# Source dependencies
source "${LIB_DIR}/colors.sh"
source "${LIB_DIR}/utils.sh"
source "${LIB_DIR}/ui.sh"

# Install settings
readonly OPENSHELL_INSTALL_DIR="${OPENSHELL_INSTALL_DIR:-$HOME/.local/bin}"
readonly OPENSHELL_VERSION="${OPENSHELL_VERSION:-latest}"
readonly OPENSHELL_REPO="NVIDIA/OpenShell"
readonly OPENSHELL_BINARY_NAME="openshell"

# Install OpenShell
install_openshell() {
    ui_stage "Installing OpenShell"
    
    # Check if already installed
    if command_exists openshell; then
        local current_version
        current_version=$(openshell --version 2>/dev/null || echo "unknown")
        ui_success "OpenShell already installed"
        ui_kv "Version" "$current_version"
        ui_kv "Path" "$(command -v openshell)"
        return 0
    fi
    
    # Ensure install directory exists
    ensure_dir "$OPENSHELL_INSTALL_DIR"
    
    ui_info "Installing OpenShell CLI..."
    ui_kv "Install Dir" "$OPENSHELL_INSTALL_DIR"
    
    # Detect platform
    local os arch target
    os=$(detect_os)
    arch=$(detect_arch)
    
    case "$os" in
        macos) os="apple-darwin" ;;
        linux) os="unknown-linux-musl" ;;
        *)
            ui_error "Unsupported OS: $os"
            return 1
            ;;
    esac
    
    target="${arch}-${os}"
    
    # Resolve version
    local version download_url filename
    if [[ "$OPENSHELL_VERSION" == "latest" ]]; then
        ui_info "Resolving latest version..."
        
        local latest_url
        latest_url="https://github.com/${OPENSHELL_REPO}/releases/latest"
        
        # Follow redirect to get version tag
        local resolved
        resolved=$(curl -fsSL -o /dev/null -w '%{url_effective}' "$latest_url" 2>/dev/null || echo "")
        version="${resolved##*/}"
        
        if [[ -z "$version" || "$version" == "latest" ]]; then
            ui_warn "Could not determine latest version, using v0.1.0"
            version="v0.1.0"
        fi
    else
        version="$OPENSHELL_VERSION"
    fi
    
    ui_kv "Version" "$version"
    ui_kv "Target" "$target"
    
    filename="${OPENSHELL_BINARY_NAME}-${target}.tar.gz"
    download_url="https://github.com/${OPENSHELL_REPO}/releases/download/${version}/${filename}"
    
    # Download
    local tmp_dir tmp_file
    tmp_dir=$(create_temp_dir)
    tmp_file="${tmp_dir}/${filename}"
    
    ui_info "Downloading ${filename}..."
    
    if ! download_file "$download_url" "$tmp_file"; then
        ui_error "Failed to download OpenShell"
        ui_info "URL: $download_url"
        cleanup_temp "$tmp_dir"
        return 1
    fi
    
    # Verify checksum (optional, if available)
    local checksums_url checksums_file
    checksums_url="https://github.com/${OPENSHELL_REPO}/releases/download/${version}/${OPENSHELL_BINARY_NAME}-checksums-sha256.txt"
    checksums_file="${tmp_dir}/checksums.txt"
    
    if download_file "$checksums_url" "$checksums_file" 2>/dev/null; then
        ui_info "Verifying checksum..."
        if command_exists shasum; then
            cd "$tmp_dir"
            if ! shasum -a 256 --ignore-missing -c checksums.txt 2>/dev/null; then
                ui_warn "Checksum verification failed, continuing anyway"
            else
                ui_success "Checksum verified"
            fi
            cd - > /dev/null
        fi
    fi
    
    # Extract
    ui_info "Extracting..."
    tar -xzf "$tmp_file" -C "$tmp_dir"
    
    # Install
    local binary_path="${tmp_dir}/${OPENSHELL_BINARY_NAME}"
    
    if [[ ! -f "$binary_path" ]]; then
        ui_error "Binary not found after extraction"
        cleanup_temp "$tmp_dir"
        return 1
    fi
    
    # Move to install directory
    chmod +x "$binary_path"
    mv "$binary_path" "${OPENSHELL_INSTALL_DIR}/${OPENSHELL_BINARY_NAME}"
    
    cleanup_temp "$tmp_dir"
    
    # Add to PATH if needed
    if ! echo "$PATH" | grep -q "$OPENSHELL_INSTALL_DIR"; then
        ui_info "Adding $OPENSHELL_INSTALL_DIR to PATH..."
        
        local profile
        profile=$(get_shell_profile)
        
        add_to_file "$profile" "# Added by NemoClaw installer"
        add_to_file "$profile" "export PATH=\"${OPENSHELL_INSTALL_DIR}:\$PATH\""
        
        # Also add to current session
        export PATH="${OPENSHELL_INSTALL_DIR}:$PATH"
    fi
    
    # Verify
    if ! command_exists openshell; then
        hash -r 2>/dev/null || true
    fi
    
    if command_exists openshell; then
        local installed_version
        installed_version=$(openshell --version 2>/dev/null || echo "$version")
        ui_success "OpenShell installed successfully"
        ui_kv "Version" "$installed_version"
        ui_kv "Path" "${OPENSHELL_INSTALL_DIR}/${OPENSHELL_BINARY_NAME}"
    else
        # Direct path check
        if [[ -x "${OPENSHELL_INSTALL_DIR}/${OPENSHELL_BINARY_NAME}" ]]; then
            ui_success "OpenShell installed"
            ui_kv "Path" "${OPENSHELL_INSTALL_DIR}/${OPENSHELL_BINARY_NAME}"
            ui_warn "Add to your PATH: export PATH=\"${OPENSHELL_INSTALL_DIR}:\$PATH\""
        else
            ui_error "Installation failed"
            return 1
        fi
    fi
    
    return 0
}

# Main
install_openshell "$@"
