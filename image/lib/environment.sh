#!/bin/sh

# Include utility functions, secrets fetching, authentication, and cleanup
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh
. /usr/local/lib/cleanup.sh

configure_environment() {
    local env_config="/home/$USER/.cd/configs/worker.yml"
    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi

    # Expand environment variables in worker.yml
    envsubst < "$env_config" > /home/$USER/.cd/configs/worker_expanded.yml
    env_config="/home/$USER/.cd/configs/worker_expanded.yml"

    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$env_config" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')
    
    # Use a loop to export each environment variable
    while IFS= read -r var; do
        eval export "$var"
    done <<< "$env_vars"

    # Authenticate actors and fetch secrets
    authenticate_actors
    fetch_secrets

    # Only after authentication and fetching secrets, cleanup actors and sensitive environment variables
    cleanup_actors
    cleanup_sensitive_env_vars
}

# Call the function to configure the environment
configure_environment
