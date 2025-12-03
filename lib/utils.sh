#!/bin/bash

# Supported secret providers (used for secret reference detection)
# Only declare if not already defined (prevents errors when sourced multiple times)
if [[ -z "${SUPPORTED_SECRET_PROVIDERS+x}" ]]; then
    readonly SUPPORTED_SECRET_PROVIDERS="gcp|azure|aws|bitwarden"
fi

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# --- Informational logs, sent to stdout (will appear as INFO in Google Cloud) ---

log_info() {
    # Removed >&2 to send to stdout
    if [ $# -eq 1 ]; then
        printf "\033[1;34m[INFO]\033[0m %s\n" "$1"
    else
        printf "\033[1;34m[INFO]\033[0m %s: %s\n" "$1" "$2"
    fi
}

log_success() {
    # Removed >&2 to send to stdout
    printf "\033[1;32m[SUCCESS]\033[0m %s: %s\n" "$1" "$2"
}

log_debug() {
    # Removed >&2 to send to stdout
    printf "\033[1;35m[DEBUG]\033[0m %s: %s\n" "$1" "$2"
}

# --- Error/Warning logs, sent to stderr (will appear as ERROR in Google Cloud) ---

log_warn() {
    # Kept >&2 to send to stderr
    printf "\033[1;33m[WARN]\033[0m %s: %s\n" "$1" "$2" >&2
}

log_error() {
    # Kept >&2 to send to stderr
    printf "\033[1;31m[ERROR]\033[0m %s: %s\n" "$1" "$2" >&2
}