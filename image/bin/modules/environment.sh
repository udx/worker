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
    
    # Load environment variables from .env file
    ENV_FILE="/home/$USER/.cd/.env"
    if [ -f "$ENV_FILE" ]; then
        set -a
        . "$ENV_FILE"
        set +a
    fi

    # Use yq to extract environment variables and export them
    yq e '.config.env | to_entries | .[] | .key + "=" + "\"" + .value + "\"" ' "$WORKER_CONFIG" | while IFS= read -r line; do
        eval "export $line"
        substituted_line=$(echo $line | envsubst)
        eval "export $substituted_line"
    done
    
    echo "Environment variables set:"
    env | grep AZURE_
}

# Function to redact secrets in logs
redact_secret() {
    echo "$1" | sed -E 's/([A-Za-z0-9_-]{3})[A-Za-z0-9_-]+([A-Za-z0-9_-]{3})/\1*********\2/g'
}

# Function to detect volume configuration and generate a warning log
detect_volumes() {
    echo "Fetching volumes configuration"
    
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    VOLUMES=$(yq e '.config.volumes[]' "$WORKER_CONFIG" 2>/dev/null)
    
    if [ -z "$VOLUMES" ]; then
        echo "Info: No volume configurations found in $WORKER_CONFIG"
        return 0
    fi
    
    echo "The following volumes are detected:"
    echo "$VOLUMES" | while read -r volume; do
        if [ -z "$volume" ]; then
            echo "Warning: Empty volume configuration found"
        else
            echo "  -v $volume"
        fi
    done
    echo "Please make sure to mount volumes when starting the container."
}

# Function to retrieve actor/secret from local cache
get_actor_secret_from_cache() {
    echo "Retrieving actor/secret from local cache"
    # Add retrieval logic here if needed
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