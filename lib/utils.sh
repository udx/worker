#!/bin/bash

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Logging functions with direct ANSI sequences
log_info() {
    if [ $# -eq 1 ]; then
        printf "\033[0;34m[INFO] %s\033[0m\n" "$1" >&2
    else
        printf "\033[0;34m[INFO] %s: %s\033[0m\n" "$1" "$2" >&2
    fi
}

log_warn() {
    printf "\033[1;33m[WARN] %s: %s\033[0m\n" "$1" "$2" >&2
}

log_error() {
    printf "\033[0;31m[ERROR] %s: %s\033[0m\n" "$1" "$2" >&2
}

log_success() {
    printf "\033[0;32m[SUCCESS] %s: %s\033[0m\n" "$1" "$2" >&2
}

udx_logo() {
    printf "\033[0;34m%s\033[0m\n" "$(cat /etc/logo.txt)"
}