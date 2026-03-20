#!/usr/bin/env bash
# SPDX-FileCopyrightText: Copyright (c) 2026 ClawBox Contributors. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Terminal color definitions for ClawBox installer

# Reset
export NC='\033[0m'

# Regular colors
export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

# Bold colors
export BOLD='\033[1m'
export BOLD_RED='\033[1;31m'
export BOLD_GREEN='\033[1;32m'
export BOLD_YELLOW='\033[1;33m'
export BOLD_BLUE='\033[1;34m'
export BOLD_MAGENTA='\033[1;35m'
export BOLD_CYAN='\033[1;36m'
export BOLD_WHITE='\033[1;37m'

# Custom theme colors (ClawBox theme)
export ACCENT='\033[38;2;255;77;77m'       # coral-bright #ff4d4d
export ACCENT_BRIGHT='\033[38;2;255;110;110m'
export SUCCESS='\033[38;2;0;229;204m'       # cyan-bright #00e5cc
export INFO='\033[38;2;136;146;176m'        # text-secondary #8892b0
export WARN='\033[38;2;255;176;32m'         # amber
export ERROR='\033[38;2;230;57;70m'         # coral-mid #e63946
export MUTED='\033[38;2;90;100;128m'        # text-muted #5a6480

# Background colors
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'

# Check if colors should be disabled
if [[ -n "${NO_COLOR:-}" ]] || [[ "${TERM:-dumb}" == "dumb" ]]; then
    export USE_COLOR=0
else
    export USE_COLOR=1
fi

# Apply color to text if colors are enabled
colorize() {
    local color="$1"
    shift
    local text="$*"
    
    if [[ "${USE_COLOR:-1}" -eq 1 ]]; then
        echo -e "${color}${text}${NC}"
    else
        echo "${text}"
    fi
}
