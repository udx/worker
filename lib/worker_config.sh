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
    local config_path="/home/${USER}/.cd/configs/worker.yml"
    
    if [[ ! -f "$config_path" ]]; then
        log_error "Configuration file not found: $config_path"
        return 1
    fi
    
    echo "$config_path"
}

# Function to load the worker configuration from YAML and convert it to JSON
load_and_resolve_worker_config() {
    local config_path
    config_path=$(get_worker_config_path)

    # Check if the config_path retrieval was successful
    if [[ -z "$config_path" ]]; then
        return 1
    fi

    # Convert the YAML configuration to JSON using yq
    local json_output
    if ! json_output=$(yq eval -o=json "$config_path" 2>/dev/null); then
        log_error "Failed to parse YAML from $config_path. yq returned an error."
        return 1
    fi

    if [[ -z "$json_output" ]]; then
        log_error "YAML parsed to an empty JSON output."
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
    if ! extracted_section=$(echo "$config_json" | jq -r ".${section}"); then
        log_error "Failed to extract section '$section' from JSON."
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
