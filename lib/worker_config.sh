#!/bin/bash

# Simple logging functions
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Get the path to the worker.yml configuration file
get_worker_config_path() {
    local config_path=".cd/configs/worker.yml"
    if [[ ! -f "$config_path" ]]; then
        log_error "No config file found at: $config_path"
        return 1
    fi
    echo "$config_path"
}

# Set environment variables from the YAML file
set_env_vars_from_yaml() {
    local config_file="$1"
    local temp_file

    # Create a temporary file for exporting environment variables
    temp_file=$(mktemp)
    if ! yq eval '.config.variables | to_entries | .[] | "export " + .key + "=" + .value' "$config_file" > "$temp_file"; then
        log_error "Failed to process environment variables from $config_file"
        rm -f "$temp_file"
        return 1
    fi

    log_info "Exporting environment variables from $config_file"
    # shellcheck source=/dev/null
    source "$temp_file"

    # Clean up the temporary file
    rm -f "$temp_file"
}

# Extract and return secrets from the YAML file
get_worker_secrets() {
    local config_file="$1"
    yq eval -o=json '.config.secrets' "$config_file" || {
        log_error "Failed to extract secrets from $config_file"
        return 1
    }
}

# Extract and return actors from the YAML file
get_worker_actors() {
    local config_file="$1"
    yq eval -o=json '.config.actors' "$config_file" || {
        log_error "Failed to extract actors from $config_file"
        return 1
    }
}

# Main function to load and resolve worker configuration
load_and_resolve_worker_config() {
    local config_path resolved_config

    # Get the configuration file path
    config_path=$(get_worker_config_path)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to retrieve worker configuration file path."
        return 1
    fi
    log_info "Config file found: $config_path"

    # Set environment variables from the configuration file
    if ! set_env_vars_from_yaml "$config_path"; then
        log_error "Failed to set environment variables."
        return 1
    fi
    log_info "Environment variables loaded successfully."

    # Extract secrets
    resolved_config=$(get_worker_secrets "$config_path")
    if [[ $? -ne 0 ]]; then
        log_error "Failed to extract secrets."
        return 1
    fi
    echo "$resolved_config" > /tmp/worker_secrets.json
    log_info "Secrets extracted successfully."

    # Extract actors
    resolved_config=$(get_worker_actors "$config_path")
    if [[ $? -ne 0 ]]; then
        log_error "Failed to extract actors."
        return 1
    fi
    echo "$resolved_config" > /tmp/worker_actors.json
    log_info "Actors extracted successfully."

    # Return the configuration path
    echo "$config_path"
}

# Example usage:
# load_and_resolve_worker_config
