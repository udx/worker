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
        nice_logs "error" "Configuration file not found at $config_path"
        return 1
    fi

    # Debugging statement
    nice_logs "info" "Found config file, resolving environment variables..."

    # Read the configuration file content
    local config_content
    config_content=$(envsubst < "$config_path")

    if [ $? -ne 0 ]; then
        nice_logs "error" "Failed to resolve environment variables in the configuration"
        return 1
    fi

    # Output the resolved configuration content
    echo "$config_content"
}

# Example usage
# resolved_config=$(load_and_resolve_worker_config)
# echo "$resolved_config"
