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

    if [ ! -f "$config_path" ]; then
        nice_logs "error" "Configuration file not found at $config_path"
        return 1
    fi

    if envsubst < "$config_path" > "$temp_config_path"; then
        nice_logs "info" "Resolved configuration written to $temp_config_path"
        echo "$temp_config_path"
    else
        nice_logs "error" "Failed to resolve environment variables in the configuration"
        return 1
    fi
}

# Extract and return the workerActors section from the resolved configuration
get_worker_actors() {
    local resolved_config="$1"
    yq e -o=json '.config.workerActors' "$resolved_config"
}

# Extract and return the workerSecrets section from the resolved configuration
get_worker_secrets() {
    local resolved_config="$1"
    yq e -o=json '.config.workerSecrets' "$resolved_config"
}

# Extract and return the env section from the resolved configuration
get_worker_env_vars() {
    local resolved_config="$1"
    yq e -o=json '.config.env' "$resolved_config"
}

# Function to set environment variables from the resolved configuration file
set_env_vars_from_config() {
    local temp_config_path="$1"
    local env_vars
    
    env_vars=$(yq e -o=json '.config.env' "$temp_config_path" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')
    
    if [ -z "$env_vars" ]; then
        nice_logs "error" "No environment variables found in the configuration"
        return 1
    fi
    
    echo "$env_vars" | while IFS= read -r var; do
        eval export "$var"
    done
}