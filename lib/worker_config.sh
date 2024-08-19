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
    if ! yq eval '.config.variables | to_entries | .[] | "export " + .key + "=" + .value' "$config_file" > /tmp/export_vars.sh; then
        log_error "Failed to process environment variables from $config_file"
        return 1
    fi

    # Source the file to set the environment variables
    log_info "Exporting environment variables from $config_file"
    # shellcheck source=/dev/null
    source /tmp/export_vars.sh

    # Clean up the temporary file
    rm -f /tmp/export_vars.sh
}

# Extract secrets from the YAML file
get_worker_secrets() {
    local config_file="$1"
    
    # Use yq to extract secrets and save them to a temporary JSON file
    if ! yq eval -o=json '.config.secrets' "$config_file" > /tmp/worker_secrets.json; then
        log_error "Failed to extract secrets from $config_file"
        return 1
    fi

    log_info "Secrets extracted successfully."
    cat /tmp/worker_secrets.json
}

# Extract actors from the YAML file
get_worker_actors() {
    local config_file="$1"

    # Use yq to extract actors and save them to a temporary JSON file
    if ! yq eval -o=json '.config.actors' "$config_file" > /tmp/worker_actors.json; then
        log_error "Failed to extract actors from $config_file"
        return 1
    fi

    log_info "Actors extracted successfully."
    cat /tmp/worker_actors.json
}

# Main function to handle the environment variables, secrets, and actors
load_and_resolve_worker_config() {
    local config_path
    config_path=$(get_worker_config_path)
    
    if [[ ! -f "$config_path" ]]; then
        log_error "No config file found at: $config_path"
        return 1
    fi

    log_info "Config file found: $config_path"

    # Set environment variables directly from the YAML file
    if ! set_env_vars_from_yaml "$config_path"; then
        log_error "Failed to set environment variables from configuration."
        return 1
    fi

    log_info "Environment variables loaded successfully."

    # Extract and handle secrets
    if ! get_worker_secrets "$config_path"; then
        log_error "Failed to extract secrets."
        return 1
    fi

    # Extract and handle actors
    if ! get_worker_actors "$config_path"; then
        log_error "Failed to extract actors."
        return 1
    fi

    log_info "Secrets and actors processed successfully."

    # Return the config path
    echo "$config_path"
}

# Example usage:
# load_and_resolve_worker_config
