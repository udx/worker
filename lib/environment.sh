#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/secrets.sh
# shellcheck source=/dev/null
source /usr/local/lib/auth.sh
# shellcheck source=/dev/null
source /usr/local/lib/cleanup.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Main function to coordinate resolving and setting up the environment
configure_environment() {
    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    
    if [ $? -ne 0 ]; then
        nice_logs "error" "Failed to load and resolve worker configuration."
        return 1
    fi

    # Set environment variables from the resolved configuration
    set_env_vars_from_config "$resolved_config"

    # Authenticate actors before fetching secrets
    authenticate_actors

    # Fetch secrets using the existing fetch_secrets script
    fetch_secrets

    # Only after authentication and fetching secrets, clean up actors and sensitive environment variables
    cleanup_actors
    cleanup_sensitive_env_vars

    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
}

# Call the main function to configure the environment
configure_environment
