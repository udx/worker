#!/bin/bash

# Include necessary modules
source /usr/local/lib/utils.sh
source /usr/local/lib/auth.sh
source /usr/local/lib/secrets.sh
source /usr/local/lib/cleanup.sh
source /usr/local/lib/worker_config.sh

# Main function to coordinate environment setup
configure_environment() {
    log_info "Starting environment configuration..."

    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_parse_config)
    if [[ -z "$resolved_config" ]]; then
        log_error "Configuration loading failed. Exiting..."
        return 1
    fi

    log_info "Worker configuration loaded successfully."

    # Extract and authenticate actors
    local actors
    actors=$(get_config_section "$resolved_config" "actors")
    if [[ $? -eq 0 && -n "$actors" ]]; then
        log_info "Authenticating actors from configuration..."
        if ! authenticate_actors "$actors"; then
            log_error "Failed to authenticate actors."
            return 1
        fi
    else
        log_info "No actors defined in the configuration."
    fi

    # Extract and fetch secrets
    local secrets
    secrets=$(get_config_section "$resolved_config" "secrets")
    if [[ $? -eq 0 && -n "$secrets" ]]; then
        log_info "Fetching secrets from configuration..."
        if ! fetch_secrets "$secrets"; then
            log_error "Failed to fetch secrets."
            return 1
        fi
    else
        log_info "No secrets defined in the configuration."
    fi

    # Perform cleanup
    log_info "Cleaning up sensitive data..."
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
