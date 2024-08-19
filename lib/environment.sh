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
    # Load environment variables from .env file if it exists
    if [ -f .env ]; then
        echo "[INFO] Loading environment variables from .env file."
        while IFS= read -r line; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            # Export the variable
            eval "export $line"
        done < .env
    else
        echo "[INFO] No .env file found. Proceeding with environment variables from the host."
    fi
    
    # Load and resolve the worker configuration
    if ! load_and_resolve_worker_config; then
        nice_logs "error" "Failed to load and resolve worker configuration."
        return 1
    fi
    
    # Authenticate actors
    if ! authenticate_actors; then
        nice_logs "error" "Authentication of actors failed."
        return 1
    fi
    
    # Fetch secrets
    if ! fetch_secrets; then
        nice_logs "error" "Fetching secrets failed."
        return 1
    fi
    
    # Clean up actors and sensitive environment variables
    cleanup_actors
    cleanup_sensitive_env_vars
}

# Call the main function
configure_environment
