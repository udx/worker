#!/bin/sh

# Source the modules
source /usr/local/bin/modules/secrets.sh
source /usr/local/bin/modules/auth.sh
source /usr/local/bin/modules/cleanup.sh

# Function to fetch environment configuration
fetch_env() {
    echo "Fetching environment configuration"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Use yq to extract environment variables and format them for export
    yq e '.config.env | to_entries | .[] | "export " + .key + "=" + "\"" + .value + "\""' "$WORKER_CONFIG" > /tmp/env_vars.sh
    
    # Source the generated script to set environment variables
    if [ -f /tmp/env_vars.sh ]; then
        . /tmp/env_vars.sh
    else
        echo "Error: Generated environment variables script not found"
        return 1
    fi

    echo "Environment configuration fetched successfully"
}

# Function to detect volume configuration and generate a warning log
detect_volumes() {
    echo "Fetching volumes configuration"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Use yq to extract volume mappings
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
    if [ -z "$env" ] || [ -z "$secrets" ]; then
        if ! fetch_env; then
            echo "Failed to fetch environment configuration"
            exit 1
        fi
        authenticate_actors
        fetch_secrets
        cleanup_actors
    else
        get_actor_secret_from_cache
        echo "Retrieving actor/secret from local cache"
    fi
    
    detect_volumes
}

# Call the main function to configure environment
configure_environment
