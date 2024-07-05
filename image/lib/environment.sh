#!/bin/sh

# Include utility functions and secrets fetching
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh

configure_environment() {
    echo "[INFO] Loading environment variables"
    if [ -f /home/$USER/.cd/.env ]; then
        export $(cat /home/$USER/.cd/.env | xargs)
    fi

    echo "[INFO] Fetching environment configuration"
    local env_config="/home/$USER/.cd/configs/worker.yml"

    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi

    # Use yq to extract environment variables in a safer way
    yq e '.config.env' "$env_config" | while IFS=": " read -r key value; do
        key=$(echo $key | xargs)  # Remove leading/trailing whitespace
        value=$(echo $value | xargs)  # Remove leading/trailing whitespace
        export "$key=$value"
    done

    # Fetch secrets and set them as environment variables
    fetch_secrets

    echo "[INFO] Environment variables set:"
    env | grep -E 'DOCKER_IMAGE_NAME|AZURE_SUBSCRIPTION_ID|AZURE_TENANT_ID|AZURE_APPLICATION_ID|AZURE_APPLICATION_PASSWORD'
}
