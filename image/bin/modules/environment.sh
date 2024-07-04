#!/bin/sh

# Source the modules
source /usr/local/bin/modules/secrets.sh
source /usr/local/bin/modules/auth.sh
source /usr/local/bin/modules/cleanup.sh

# Function to load environment variables from .env file or prompt for password
load_env() {
    echo "Loading environment variables"
    
    ENV_FILE="/home/$USER/.cd/.env"
    PASSWORD_FILE="/home/$USER/.cd/password"
    
    # Load environment variables from .env file if it exists
    if [ -f "$ENV_FILE" ]; then
        set -a
        . "$ENV_FILE"
        set +a
    fi
    
    # Check if AZURE_APPLICATION_PASSWORD is set, if not prompt for it
    if [ -f "$PASSWORD_FILE" ]; then
        export AZURE_APPLICATION_PASSWORD=$(cat "$PASSWORD_FILE")
    elif [ -z "$AZURE_APPLICATION_PASSWORD" ]; then
        if [ -t 0 ]; then
            read -sp "Enter AZURE_APPLICATION_PASSWORD: " AZURE_APPLICATION_PASSWORD
            echo
        else
            echo "AZURE_APPLICATION_PASSWORD is not set and not running interactively. Exiting."
            exit 1
        fi
    fi
}

# Function to fetch environment configuration
fetch_env() {
    echo "Fetching environment configuration"
    
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Use yq to extract environment variables and export them
    yq e '.config.env | to_entries | .[] | .key + "=" + "\"" + .value + "\"" ' "$WORKER_CONFIG" | while IFS= read -r line; do
        eval "export $line"
        key=$(echo $line | cut -d '=' -f 1)
        eval "export $key=$(echo \$$key | envsubst)"
    done
    
    echo "Environment variables set:"
    env | grep AZURE_
    env | grep DOCKER_IMAGE_NAME
}

# Main function to configure environment
configure_environment() {
    # Load environment variables
    load_env

    if [ -z "$env" ]; then
        if ! fetch_env; then
            echo "Failed to fetch environment configuration"
            exit 1
        fi
    fi
    
    authenticate_actors || echo "No actors configuration found"
    
    if [ -z "$secrets" ]; then
        fetch_secrets || echo "No secrets configuration found"
    fi
    
    detect_volumes
}
