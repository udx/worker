#!/bin/bash

# Include utility functions and the worker config handler
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/auth.sh
# shellcheck source=/dev/null
source /usr/local/lib/secrets.sh
# shellcheck source=/dev/null
source /usr/local/lib/cleanup.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Main function to coordinate environment setup
configure_environment() {
    
    # Load environment variables from .env file
    if [ ! -f .env ]; then
        nice_logs "info" "No .env file found"
    else
        nice_logs "info" "Loading environment variables from .env file"
        export $(grep -v '^#' .env | xargs)
    fi
    
    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    
    if [ $? -ne 0 ] || [ ! -f "$resolved_config" ]; then
        nice_logs "error" "Failed to load and resolve worker configuration or file not found."
        return 1
    fi
    
    nice_logs "info" "Using resolved configuration file at: $resolved_config"
    
    # Set environment variables from the resolved configuration
    set_env_vars_from_config "$resolved_config"
    if [ $? -ne 0 ]; then
        nice_logs "error" "Failed to set environment variables from configuration."
        return 1
    fi
    
    # Authenticate actors
    authenticate_actors
    
    # Fetch secrets
    fetch_secrets
    
    # Clean up actors and sensitive environment variables
    cleanup_actors
    cleanup_sensitive_env_vars
}

# Call the main function
configure_environment
