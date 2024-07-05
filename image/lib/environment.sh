#!/bin/sh

# Include utility functions, secrets fetching, and authentication
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh

configure_environment() {
    echo "[INFO] Loading environment variables"
    if [ -f /home/$USER/.cd/.env ]; then
        export $(grep -v '^#' /home/$USER/.cd/.env | xargs)
    fi

    echo "[INFO] Environment variables after loading .env file:"
    env | grep -E 'DOCKER_IMAGE_NAME|AZURE_SUBSCRIPTION_ID|AZURE_TENANT_ID|AZURE_APPLICATION_ID|AZURE_APPLICATION_PASSWORD'

    echo "[INFO] Fetching environment configuration"
    local env_config="/home/$USER/.cd/configs/worker.yml"

    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi

    # Use yq to extract environment variables and handle them correctly
    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$env_config" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')

    # Export the environment variables, resolving placeholders
    eval $(echo "$env_vars" | envsubst)
    export $(echo "$env_vars" | envsubst | sed "s/'//g")

    echo "[INFO] Environment variables after processing worker.yml:"
    env | grep -E 'DOCKER_IMAGE_NAME|AZURE_SUBSCRIPTION_ID|AZURE_TENANT_ID|AZURE_APPLICATION_ID|AZURE_APPLICATION_PASSWORD'

    echo "[INFO] Authenticating actors..."
    authenticate_actors

    echo "[INFO] Fetching secrets"
    fetch_secrets

    echo "[INFO] Environment variables set after fetching secrets:"
    env | grep -E 'DOCKER_IMAGE_NAME|AZURE_SUBSCRIPTION_ID|AZURE_TENANT_ID|AZURE_APPLICATION_ID|AZURE_APPLICATION_PASSWORD|AZURE_SECRET'
}

configure_environment
