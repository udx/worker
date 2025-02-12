#!/bin/bash

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Logging functions with direct ANSI sequences
# log_info() {
#     if [ $# -eq 1 ]; then
#         printf "\033[0;34m[INFO] %s\033[0m\n" "$1" >&2
#     else
#         printf "\033[0;34m[INFO] %s: %s\033[0m\n" "$1" "$2" >&2
#     fi
# }
log_info() {
    if [ $# -eq 1 ]; then
        printf "ℹ️  %s\n" "$1" >&2
    else
        printf "ℹ️  %s: %s\n" "$1" "$2" >&2
    fi
}

log_warn() {
    printf "⚠️  %s: %s\n" "$1" "$2" >&2
}

log_error() {
    printf "❌ %s: %s\n" "$1" "$2" >&2
}

log_success() {
    printf "✅ %s: %s\n" "$1" "$2" >&2
}

log_debug() {
    printf "%s: %s\n" "$1" "$2" >&2
}