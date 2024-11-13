#!/bin/bash

# Include necessary modules
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
source /usr/local/lib/auth.sh
source /usr/local/lib/secrets.sh
source /usr/local/lib/cleanup.sh
source /usr/local/lib/worker_config.sh

# Main function to coordinate environment setup
configure_environment() {
    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    if [ -z "$resolved_config" ]; then
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

    # Extract actors section and authenticate
    local actors
    actors=$(get_worker_section "$resolved_config" "config.actors")
    if [[ $? -eq 0 && -n "$actors" ]]; then
        if ! authenticate_actors "$actors"; then
            log_error "Failed to authenticate actors."
            return 1
        fi
    else
        log_info "No actors defined or required for authentication."
    fi

    # Extract secrets section and fetch secrets if available
    local secrets
    secrets=$(get_worker_section "$resolved_config" "config.secrets")
    if [[ $? -eq 0 && -n "$secrets" ]]; then
        if ! fetch_secrets "$secrets"; then
            log_error "Failed to fetch secrets."
            return 1
        fi
    else
        log_info "No secrets found or required in the configuration."
    fi

    # Clean up actors and sensitive environment variables
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
