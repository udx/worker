#!/bin/bash

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

log_info() {
    if [ $# -eq 1 ]; then
        printf "\033[1;34m[INFO]\033[0m %s\n" "$1" >&2
    else
        printf "\033[1;34m[INFO]\033[0m %s: %s\n" "$1" "$2" >&2
    fi
}

log_warn() {
    printf "\033[1;33m[WARN]\033[0m %s: %s\n" "$1" "$2" >&2
}

log_error() {
    printf "\033[1;31m[ERROR]\033[0m %s: %s\n" "$1" "$2" >&2
}

log_success() {
    printf "\033[1;32m[SUCCESS]\033[0m %s: %s\n" "$1" "$2" >&2
}

log_debug() {
    printf "\033[1;35m[DEBUG]\033[0m %s: %s\n" "$1" "$2" >&2
}