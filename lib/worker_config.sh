#!/bin/bash

# Utility functions for logging
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# Function to get the path to the worker.yml configuration file
get_worker_config_path() {
    echo "/home/${USER}/.cd/configs/worker.yml"
}

# Function to load the worker configuration from YAML and convert it to JSON
load_and_resolve_worker_config() {
    local config_path
    config_path=$(get_worker_config_path)

    if [[ ! -f "$config_path" ]]; then
        log_error "No config file found at: $config_path"
        return 1
    fi

    # Convert the YAML configuration to JSON using yq
    local json_output
    json_output=$(yq eval -o=json "$config_path" 2>/dev/null)

    if [[ $? -ne 0 || -z "$json_output" ]]; then
        log_error "Failed to parse YAML from $config_path. yq returned an error."
        return 1
    fi

    echo "$json_output"
}

# Function to extract a specific section from the JSON configuration
get_worker_section() {
    local config_json="$1"
    local section="$2"

    if [[ -z "$config_json" ]]; then
        log_error "Empty configuration JSON provided."
        return 1
    fi

    local extracted_section
    extracted_section=$(echo "$config_json" | jq -r ".${section}" 2>&1)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to extract section '$section' from worker config. jq error: $extracted_section"
        return 1
    fi

    if [[ -z "$extracted_section" || "$extracted_section" == "null" ]]; then
        log_error "Section '$section' is empty or null."
        return 1
    fi

    echo "$extracted_section"
}

# Example usage of the above functions
# You can comment this out if it’s just a library
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_environment
fi
