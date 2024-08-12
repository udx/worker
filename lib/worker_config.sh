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
    local temp_config_path="/tmp/worker.yml.resolved"

    # Debugging statement
    nice_logs "info" "Looking for config file at: $config_path"

    if [ ! -f "$config_path" ]; then
        nice_logs "error" "Configuration file not found at $config_path"
        return 1
    fi

    # Debugging statement
    nice_logs "info" "Found config file, resolving environment variables..."

    if envsubst < "$config_path" > "$temp_config_path"; then
        nice_logs "info" "Resolved configuration written to $temp_config_path"
        echo "$temp_config_path"
    else
        nice_logs "error" "Failed to resolve environment variables in the configuration"
        return 1
    fi

    # Final check to ensure the file was created
    if [ ! -f "$temp_config_path" ]; then
        nice_logs "error" "Resolved configuration file not created at $temp_config_path"
        return 1
    fi
}
