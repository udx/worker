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
# source /usr/local/lib/worker_config.sh

# Main function to coordinate environment setup
configure_environment() {
    # Load environment variables from .env file if it exists
    if [ -f .env ]; then
        echo "[INFO] Loading environment variables from .env file."
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            # Safely export the variable
            eval "export $line"
        done < .env
    else
        echo "[INFO] No .env file found. Proceeding with environment variables from the host."
    fi

    log_info "worker.yml is disabled for now. Is in progress to be fixed."
    
    # # Load and resolve the worker configuration
    # if ! load_and_resolve_worker_config; then
    #     log_error "Failed to load and resolve worker configuration."
    #     return 1
    # fi
    
    # # Authenticate actors
    # if ! authenticate_actors; then
    #     log_error "Failed to authenticate actors."
    #     return 1
    # fi
    
    # # Fetch secrets
    # if ! fetch_secrets; then
    #     log_error "Failed to fetch secrets."
    #     return 1
    # fi
    
    # # Clean up actors and sensitive environment variables
    # cleanup_actors || log_error "Failed to clean up actors."
    # cleanup_sensitive_env_vars || log_error "Failed to clean up sensitive environment variables."
}

# Call the main function
configure_environment
