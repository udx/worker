#!/bin/bash

# Include utility functions
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh

# Get the path to the worker.yml configuration file
get_worker_config_path() {
    local config_path=".cd/configs/worker.yml"
    echo "$config_path"
}

# Function to set environment variables from configuration
set_env_vars_from_config() {
    local config_file="$1"
    
    # Use yq to parse and extract configurations
    local env_config
    env_config=$(yq eval '.config.variables' "$config_file")
    
    # Check if env_config is empty or invalid
    if [ -z "$env_config" ]; then
        nice_logs "error" "Environment configuration is empty or invalid."
        return 1
    fi

    # Set environment variables
    echo "$env_config" | jq -r 'to_entries[] | "\(.key)=\(.value | tostring)"' | while IFS='=' read -r key value; do
        # Skip empty keys or values
        if [ -n "$key" ] && [ -n "$value" ]; then
            export "$key=$value"
        else
            nice_logs "warning" "Skipping invalid key-value pair: $key=$value"
        fi
    done
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
    
    # Set environment variables from the resolved configuration
    if ! set_env_vars_from_config "$config_path"; then
        nice_logs "error" "Failed to set environment variables from configuration."
        return 1
    fi

    # Return path to the configuration file (if needed)
    echo "$config_path"
}
