#!/bin/sh

# Include utility functions, secrets fetching, authentication, and cleanup
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh
. /usr/local/lib/cleanup.sh

configure_environment() {
    # Load environment variables from .env file if it exists
    if [ -f /home/$USER/.cd/.env ]; then
        echo "[INFO] Loading environment variables from .env file"
        set -a
        . /home/$USER/.cd/.env
        set +a
    else
        echo "[ERROR] .env file not found"
    fi

    local env_config="/home/$USER/.cd/configs/worker.yml"
    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi

    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$env_config" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')
    
    # Use a loop to export each environment variable
    while IFS= read -r var; do
        eval export "$var"
    done <<< "$env_vars"

    # Authenticate actors and fetch secrets
    authenticate_actors
    fetch_secrets

    # Cleanup sensitive environment variables
    cleanup_sensitive_env_vars

    # Verify DOCKER_IMAGE_NAME
    if [ -z "$DOCKER_IMAGE_NAME" ]; then
        echo "[ERROR] DOCKER_IMAGE_NAME is not set after fetching secrets and cleanup"
    else
        echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after fetching secrets and cleanup"
    fi
}
