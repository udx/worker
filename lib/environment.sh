#!/bin/bash

# Include necessary modules
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/auth.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/secrets.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/cleanup.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/worker_config.sh"

# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Main function to coordinate environment setup
configure_environment() {
    log_info "Starting environment configuration..."

    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_parse_config)
    if [[ -z "$resolved_config" ]]; then
        log_error "Environment" "Configuration loading failed. Exiting..."
        return 1
    fi

    # Export variables from the configuration
    if ! export_variables_from_config "$resolved_config"; then
        log_error "Environment" "Failed to export variables."
        return 1
    fi

    # Extract and authenticate actors
    local actors
    actors=$(get_config_section "$resolved_config" "actors")
    if [[ $? -eq 0 && -n "$actors" ]]; then
        log_info "Authenticating actors from configuration..."
        if ! authenticate_actors "$actors"; then
            log_error "Environment" "Failed to authenticate actors."
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
            log_error "Environment" "Failed to fetch secrets."
            return 1
        fi
    else
        log_info "No secrets defined in the configuration."
    fi

    # Perform cleanup
    log_info "Cleaning up sensitive data..."
    if ! cleanup_actors; then
        log_error "Environment" "Failed to clean up actors."
        return 1
    fi

    # Environment setup complete
    log_info "Secure environment setup completed successfully."
}

# Call the main function
configure_environment
