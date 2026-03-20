#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# UI functions for ClawBox installer

# Source dependencies
if [[ -z "${NC:-}" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi
source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# UI state
export UI_STAGE_TOTAL=5
export UI_STAGE_CURRENT=0

# Print info message
ui_info() {
    local msg="$*"
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${MUTED}·${NC} ${msg}"
    else
        echo "· ${msg}"
    fi
}

# Print success message
ui_success() {
    local msg="$*"
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${SUCCESS}✓${NC} ${msg}"
    else
        echo "✓ ${msg}"
    fi
}

# Print warning message
ui_warn() {
    local msg="$*"
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${WARN}!${NC} ${msg}"
    else
        echo "! ${msg}"
    fi
}

# Print error message
ui_error() {
    local msg="$*"
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${ERROR}✗${NC} ${msg}" >&2
    else
        echo "✗ ${msg}" >&2
    fi
}

# Print section header
ui_section() {
    local title="$*"
    echo ""
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${ACCENT}${BOLD}${title}${NC}"
    else
        echo "== ${title} =="
    fi
}

# Print stage header with counter
ui_stage() {
    local title="$*"
    UI_STAGE_CURRENT=$((UI_STAGE_CURRENT + 1))
    ui_section "[${UI_STAGE_CURRENT}/${UI_STAGE_TOTAL}] ${title}"
}

# Print key-value pair
ui_kv() {
    local key="$1"
    local value="$2"
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        printf "  ${MUTED}%-20s${NC} ${value}\n" "${key}:"
    else
        printf "  %-20s %s\n" "${key}:" "${value}"
    fi
}

# Print progress bar
ui_progress() {
    local current="$1"
    local total="$2"
    local label="${3:-}"
    
    local width=40
    local percent=$(( current * 100 / total ))
    local filled=$(( current * width / total ))
    local empty=$(( width - filled ))
    
    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        printf "\r  ${CYAN}%s${NC} %3d%% %s" "$bar" "$percent" "$label"
    else
        printf "\r  [%s] %3d%% %s" "$bar" "$percent" "$label"
    fi
    
    if [[ "$current" -ge "$total" ]]; then
        echo ""
    fi
}

# Print animated spinner
ui_spinner() {
    local pid=$1
    local label="${2:-Processing}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) % ${#spin} ))
        if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
            printf "\r  ${CYAN}%s${NC} %s" "${spin:$i:1}" "$label"
        else
            printf "\r  [%c] %s" "${spin:$i:1}" "$label"
        fi
        sleep 0.1
    done
    printf "\r"
}

# Run command with spinner
ui_run_spinner() {
    local label="$1"
    shift
    local log
    log=$(create_temp_file)
    
    "$@" > "$log" 2>&1 &
    local pid=$!
    
    ui_spinner "$pid" "$label"
    wait "$pid"
    local exit_code=$?
    
    if [[ $exit_code -ne 0 ]]; then
        ui_error "${label} failed"
        if [[ -s "$log" ]]; then
            tail -n 20 "$log" >&2
        fi
    fi
    
    rm -f "$log"
    return $exit_code
}

# Print banner
ui_banner() {
    local version="${1:-1.0.0}"

    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo ""
        echo -e "${ACCENT}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${ACCENT}║${NC}                                                                ${ACCENT}║${NC}"
        echo -e "${ACCENT}║${NC}    ${BOLD}🦞 ClawBox${NC} - Secure AI Assistant in a Box             ${ACCENT}║${NC}"
        echo -e "${ACCENT}║${NC}    ${MUTED}Cross-platform installer for OpenClaw + NemoClaw${NC}       ${ACCENT}║${NC}"
        echo -e "${ACCENT}║${NC}                                                                ${ACCENT}║${NC}"
        echo -e "${ACCENT}║${NC}    ${INFO}Version: ${version}${NC}                                        ${ACCENT}║${NC}"
        echo -e "${ACCENT}║${NC}                                                                ${ACCENT}║${NC}"
        echo -e "${ACCENT}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                                                                ║"
        echo "║    🦞 ClawBox - Secure AI Assistant in a Box                  ║"
        echo "║    Cross-platform installer for OpenClaw + NemoClaw           ║"
        echo "║                                                                ║"
        echo "║    Version: ${version}                                        ║"
        echo "║                                                                ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
    fi
}

# Print completion banner
ui_complete() {
    local sandbox_name="${1:-my-assistant}"
    local project_dir="${2:-.}"
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo ""
        echo -e "${SUCCESS}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}    ${BOLD_GREEN}✅ Installation Complete!${NC}                                  ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}    ${INFO}Quick Start:${NC}                                               ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}      ${CYAN}nemoclaw ${sandbox_name} connect${NC}     ${MUTED}# Connect to sandbox${NC}   ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}      ${CYAN}openclaw tui${NC}                      ${MUTED}# Launch OpenClaw TUI${NC}    ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}      ${CYAN}openshell term${NC}                    ${MUTED}# Monitor network${NC}        ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}    ${INFO}Data Directory:${NC}                                             ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}      ${MUTED}${project_dir}/openclaw-data/${NC}                             ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}    ${MUTED}Get NVIDIA API Key: https://build.nvidia.com${NC}              ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}║${NC}                                                                ${SUCCESS}║${NC}"
        echo -e "${SUCCESS}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
    else
        echo ""
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║                                                                ║"
        echo "║    ✅ Installation Complete!                                   ║"
        echo "║                                                                ║"
        echo "║    Quick Start:                                                ║"
        echo "║                                                                ║"
        echo "║      nemoclaw ${sandbox_name} connect     # Connect to sandbox  ║"
        echo "║      openclaw tui                      # Launch OpenClaw TUI   ║"
        echo "║      openshell term                    # Monitor network       ║"
        echo "║                                                                ║"
        echo "║    Data Directory:                                             ║"
        echo "║      ${project_dir}/openclaw-data/                             ║"
        echo "║                                                                ║"
        echo "║    Get NVIDIA API Key: https://build.nvidia.com               ║"
        echo "║                                                                ║"
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
    fi
}

# Prompt for input
ui_prompt() {
    local prompt="$1"
    local default="${2:-}"
    local result
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -en "${CYAN}?${NC} ${prompt}"
        [[ -n "$default" ]] && echo -en " ${MUTED}[${default}]${NC}"
        echo -en ": "
    else
        echo -en "? ${prompt}"
        [[ -n "$default" ]] && echo -en " [${default}]"
        echo -en ": "
    fi
    
    read -r result
    echo "${result:-$default}"
}

# Prompt for password (hidden input)
ui_prompt_password() {
    local prompt="$1"
    local result
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -en "${CYAN}?${NC} ${prompt}: "
    else
        echo -en "? ${prompt}: "
    fi
    
    read -rs result
    echo ""
    echo "$result"
}

# Prompt for confirmation
ui_confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local result
    
    local options
    if [[ "$default" == "y" ]]; then
        options="Y/n"
    else
        options="y/N"
    fi
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -en "${CYAN}?${NC} ${prompt} ${MUTED}[${options}]${NC}: "
    else
        echo -en "? ${prompt} [${options}]: "
    fi
    
    read -r result
    result="${result:-$default}"
    
    [[ "$result" =~ ^[Yy]$ ]]
}

# Select from options
ui_select() {
    local prompt="$1"
    shift
    local options=("$@")
    local selected=1
    
    echo ""
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${CYAN}?${NC} ${prompt}"
    else
        echo "? ${prompt}"
    fi
    echo ""
    
    local i=1
    for opt in "${options[@]}"; do
        if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
            echo -e "  ${MUTED}${i}.${NC} ${opt}"
        else
            echo "  ${i}. ${opt}"
        fi
        ((i++))
    done
    echo ""
    
    local choice
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -en "${CYAN}?${NC} Select (1-${#options[@]}): "
    else
        echo -en "? Select (1-${#options[@]}): "
    fi
    
    read -r choice
    if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
        echo "${options[$((choice-1))]}"
    else
        echo "${options[0]}"
    fi
}

# Print panel with border
ui_panel() {
    local title="$1"
    shift
    local content=("$@")
    
    local width=64
    local border_char="─"
    local corner_tl="┌"
    local corner_tr="┐"
    local corner_bl="└"
    local corner_br="┘"
    local side="│"
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${ACCENT}${corner_tl}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${corner_tr}${NC}"
        
        if [[ -n "$title" ]]; then
            local title_pad=$(( (width - ${#title} - 2) / 2 ))
            printf "${ACCENT}${side}${NC}%*s${BOLD}%s${NC}%*s${ACCENT}${side}${NC}\n" $title_pad "" "$title" $(( width - title_pad - ${#title} - 2 )) ""
            echo -e "${ACCENT}${side}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${side}${NC}"
        fi
        
        for line in "${content[@]}"; do
            printf "${ACCENT}${side}${NC} %-62s${ACCENT}${side}${NC}\n" "$line"
        done
        
        echo -e "${ACCENT}${corner_bl}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${corner_br}${NC}"
    else
        echo "${corner_tl}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${corner_tr}"
        
        if [[ -n "$title" ]]; then
            local title_pad=$(( (width - ${#title} - 2) / 2 ))
            printf "${side}%*s%s%*s${side}\n" $title_pad "" "$title" $(( width - title_pad - ${#title} - 2 )) ""
        fi
        
        for line in "${content[@]}"; do
            printf "${side} %-62s${side}\n" "$line"
        done
        
        echo "${corner_bl}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_char}${border_br}"
    fi
}
