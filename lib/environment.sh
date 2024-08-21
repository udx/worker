#!/bin/bash

# Include utility functions and necessary modules
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
source /usr/local/lib/auth.sh  # Make sure this script contains the authenticate_actors function
source /usr/local/lib/secrets.sh
source /usr/local/lib/cleanup.sh
source /usr/local/lib/worker_config.sh

# Simple logging functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Load environment variables from .env file if it exists
load_env_file() {
    if [ -f .env ]; then
        log_info "Loading environment variables from .env file."
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            eval "export $line"
        done < .env
    else
        log_info "No .env file found. Proceeding with environment variables from the host."
    fi
}

# Main function to coordinate environment setup
configure_environment() {
    # Load environment variables from .env file if it exists
    load_env_file

    # Load and resolve the worker configuration
    local config_path
    config_path=$(get_worker_config_path)

    if [[ ! -f "$config_path" ]]; then
        log_error "No config file found at: $config_path"
        return 1
    fi

    # Load and resolve worker configuration using the worker_config module
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config "$config_path")
    if [[ $? -ne 0 ]]; then
        log_error "Failed to resolve worker configuration."
        return 1
    fi

    # Authenticate actors using the resolved configuration
    if ! authenticate_actors "$resolved_config"; then
        log_error "Failed to authenticate actors."
        return 1
    fi

    # Fetch secrets using the resolved configuration
    if ! fetch_secrets_from_config "$resolved_config"; then
        log_error "Failed to fetch secrets."
        return 1
    fi

    # Clean up actors and sensitive environment variables
    cleanup_actors || log_error "Failed to clean up actors."
    cleanup_sensitive_env_vars || log_error "Failed to clean up sensitive environment variables."

    log_info "Environment setup completed successfully."
}

# Call the main function
configure_environment
