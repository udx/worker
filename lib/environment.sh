#!/bin/bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source a file if it exists
source_if_exists() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
        # shellcheck disable=SC1090
        source "$file_path"
    else
        echo "[ERROR] Missing file: $file_path" >&2
        exit 1
    fi
}

# Include necessary modules from the same directory
# shellcheck source=./utils.sh
source_if_exists "$SCRIPT_DIR/utils.sh"
# shellcheck source=./auth.sh
source_if_exists "$SCRIPT_DIR/auth.sh"
# shellcheck source=./secrets.sh
source_if_exists "$SCRIPT_DIR/secrets.sh"
# shellcheck source=./cleanup.sh
source_if_exists "$SCRIPT_DIR/cleanup.sh"
# shellcheck source=./process_manager.sh
source_if_exists "$SCRIPT_DIR/process_manager.sh"
# shellcheck source=./worker_config.sh
source_if_exists "$SCRIPT_DIR/worker_config.sh"

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

    # Export variables from the configuration
    log_info "Exporting variables from configuration to environment..."
    if ! export_variables_from_config "$resolved_config"; then
        log_error "Failed to export variables."
        return 1
    fi

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

    # Perform process manager setup
    log_info "Setting up process manager..."
    if should_generate_config; then
        echo "Generating Supervisor configurations..."
        configure_and_execute_services
    else
        echo "No services found in $CONFIG_FILE. Skipping Supervisor configuration."
    fi

    log_info "Secure environment setup completed successfully."
}

# Call the main function
configure_environment
