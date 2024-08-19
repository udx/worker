#!/bin/bash

# Simple logging functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# Get the path to the worker.yml configuration file
get_worker_config_path() {
    echo ".cd/configs/worker.yml"
}

# Directly set environment variables from the YAML file
set_env_vars_from_yaml() {
    local config_file="$1"
    
    # Use yq to parse and directly export the environment variables
    yq eval '.config.variables | to_entries | .[] | "export " + .key + "=" + .value' "$config_file" > /tmp/export_vars.sh

    if [ $? -ne 0 ]; then
        log_error "Failed to process environment variables from $config_file"
        return 1
    fi

    # Source the file to set the environment variables
    log_info "Exporting environment variables from $config_file"
    source /tmp/export_vars.sh

    # Clean up the temporary file
    rm /tmp/export_vars.sh
}

# Main function to handle the environment variables
load_and_resolve_worker_config() {
    local config_path
    config_path=$(get_worker_config_path)
    
    if [ ! -f "$config_path" ]; then
        log_error "No config file found at: $config_path"
        return 1
    fi

    log_info "Config file found: $config_path"

    # Set environment variables directly from the YAML file
    set_env_vars_from_yaml "$config_path" || {
        log_error "Failed to set environment variables from configuration."
        return 1
    }

    log_info "Environment variables loaded successfully."
}
