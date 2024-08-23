#!/bin/bash

# Include necessary modules
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
source /usr/local/lib/auth.sh
source /usr/local/lib/secrets.sh
source /usr/local/lib/cleanup.sh
source /usr/local/lib/worker_config.sh

# Load environment variables from .env file if it exists
load_env_file() {
    if [ -f .env ]; then
        log_info "Loading environment variables from .env file."
        # Directly export each line from the .env file
        export $(grep -v '^#' .env | xargs -r)
    else
        log_info "No .env file found. Proceeding with environment variables from the host."
    fi
}

# Main function to coordinate environment setup
# Main function to coordinate environment setup
configure_environment() {
    # Load environment variables from .env file if it exists
    load_env_file

    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    if [ $? -ne 0 ]; then
        log_error "Failed to resolve worker configuration."
        return 1
    fi

    # Verify the config file exists at the expected path
    local config_path
    config_path=$(get_worker_config_path)
    if [[ ! -f "$config_path" ]]; then
        log_error "Configuration file not found at: $config_path"
        return 1
    fi
    log_info "Config file found: $config_path"

    # Extract actors section from the resolved configuration
    local actors
    actors=$(get_worker_section "$resolved_config" "config.actors")
    # log_debug "Extracted actors: $actors"
    if [ -z "$actors" ]; then
        log_error "No actors found in the configuration."
        return 1
    fi

    # # Authenticate actors using the extracted actors section
    if ! authenticate_actors "$actors"; then
        log_error "Failed to authenticate actors."
        return 1
    fi

    # Extract secrets section from the resolved configuration
    local secrets
    secrets=$(get_worker_section "$resolved_config" "config.secrets")
    # log_debug "Extracted secrets: $secrets"
    if [ -z "$secrets" ]; then
        log_error "No secrets found in the configuration."
        return 1
    fi

    # # Fetch secrets using the resolved configuration
    if ! fetch_secrets "$secrets"; then
        log_error "Failed to fetch secrets."
        return 1
    fi

    # # Clean up actors and sensitive environment variables
    if ! cleanup_actors; then
        log_error "Failed to clean up actors."
        return 1
    fi

    if ! cleanup_sensitive_env_vars; then
        log_error "Failed to clean up sensitive environment variables."
        return 1
    fi

    log_info "Environment setup completed successfully."
}


# Call the main function
configure_environment
