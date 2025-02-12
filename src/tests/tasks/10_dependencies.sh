#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

log_info "Dependencies: Validating required dependencies and their versions"

# Function to test if a command is available and show its version
check_command() {
    local cmd_path
    cmd_path=$(command -v "$1")
    if [ -x "$cmd_path" ]; then
        log_success "$1" "$1 is installed at $cmd_path"
        local version
        version=$($1 --version 2>&1 | head -n 1)
        log_success "$1" "Version: $version"
    else
        log_error "$1" "Not installed or not in PATH"
        exit 1
    fi
}

# Verify gcloud, aws, az, bw, yq, and jq commands are available
log_info "Checking cloud provider CLIs..."
check_command gcloud
check_command aws
check_command az

log_info "Checking utility tools..."
check_command bw
check_command yq
check_command jq

log_success "Dependencies" "All dependencies validated successfully"