#!/bin/bash

# Include utility functions
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh

# Get the path to the worker.yml configuration file
get_worker_config_path() {
    local config_path="/home/$USER/.cd/configs/worker.yml"
    echo "$config_path"
}

# Load and resolve environment variables in the worker.yml configuration file
load_and_resolve_worker_config() {
    local config_path
    config_path=$(get_worker_config_path)
    
    # Debugging statement
    nice_logs "info" "Looking for config file at: $config_path"
    
    if [ ! -f "$config_path" ]; then
        nice_logs "info" "No config file found at: $config_path"
        return 1
    fi

    # Load configuration
    nice_logs "info" "Found config file, processing configuration..."
    
    # Use yq to parse and extract configurations
    local env_config
    env_config=$(yq eval '.config.variables' "$config_path")

    echo "test"
    echo $env_config

    # Set environment variables
    echo "$env_config" | jq -r 'to_entries[] | "\(.key)=\(.value|tostring)"' | while IFS='=' read -r key value; do
        # Skip empty keys or values
        if [ -n "$key" ] && [ -n "$value" ]; then
            export "$key=$value"
        fi
    done

    # Return path to the configuration file (if needed)
    echo "$config_path"
}
