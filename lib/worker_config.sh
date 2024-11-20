#!/bin/bash

# Utility functions for logging
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# Paths for configurations
BUILT_IN_CONFIG="/usr/src/app/src/configs/worker.yml"
USER_CONFIG="/home/${USER}/.cd/configs/worker.yml"
MERGED_CONFIG="/home/${USER}/.cd/configs/merged_worker.yml"

# Function to ensure configuration file exists
ensure_config_exists() {
    local config_path="$1"
    if [[ ! -f "$config_path" ]]; then
        log_error "Configuration file not found: $config_path"
        return 1
    fi
}

# Function to merge the built-in and user-provided configuration files
merge_worker_configs() {
    log_info "Merging worker configurations..."

    # Ensure the built-in config exists
    ensure_config_exists "$BUILT_IN_CONFIG" || return 1

    if [[ -f "$USER_CONFIG" ]]; then
        log_info "User-provided configuration detected. Merging with the built-in configuration."

        # Merge user config with built-in config, prioritizing user config
        if ! yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BUILT_IN_CONFIG" "$USER_CONFIG" > "$MERGED_CONFIG"; then
            log_error "Failed to merge configurations. yq returned an error."
            return 1
        fi
    else
        log_info "No user-provided configuration detected. Using the built-in configuration."
        cp "$BUILT_IN_CONFIG" "$MERGED_CONFIG"
    fi

    log_info "Configuration merged successfully: $MERGED_CONFIG"
}

# Function to load the merged configuration and convert it to JSON
load_and_parse_config() {
    merge_worker_configs || return 1

    # Convert the merged YAML configuration to JSON using yq
    local json_output
    if ! json_output=$(yq eval -o=json "$MERGED_CONFIG" 2>/dev/null); then
        log_error "Failed to parse merged YAML from $MERGED_CONFIG. yq returned an error."
        return 1
    fi

    if [[ -z "$json_output" ]]; then
        log_error "Merged YAML parsed to an empty JSON output."
        return 1
    fi

    echo "$json_output"
}

# Function to extract a specific section from the JSON configuration
get_config_section() {
    local config_json="$1"
    local section="$2"

    if [[ -z "$config_json" ]]; then
        log_error "Empty configuration JSON provided."
        return 1
    fi

    # Attempt to extract the section and handle missing/null cases
    local extracted_section
    extracted_section=$(echo "$config_json" | jq -r ".config.${section} // empty" 2>/dev/null)

    if [[ $? -ne 0 ]]; then
        log_error "Failed to parse section '${section}' from configuration."
        return 1
    fi

    if [[ -z "$extracted_section" || "$extracted_section" == "null" ]]; then
        log_info "Section '${section}' is not defined in the configuration."
        return 0
    fi

    echo "$extracted_section"
}

# Debugging helper: Validate JSON structure
validate_json() {
    local json="$1"
    if ! echo "$json" | jq empty 2>/dev/null; then
        log_error "Invalid JSON structure detected."
        return 1
    fi
}

# Example usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Loading and resolving worker configuration..."
    config_json=$(load_and_parse_config) || exit 1
    validate_json "$config_json" || exit 1
    log_info "Worker configuration loaded successfully."

    # Extract and process sections
    actors=$(get_config_section "$config_json" "actors")
    if [[ $? -eq 0 && -n "$actors" ]]; then
        log_info "Actors loaded: $actors"
    fi

    secrets=$(get_config_section "$config_json" "secrets")
    if [[ $? -eq 0 && -n "$secrets" ]]; then
        log_info "Secrets loaded: $secrets"
    fi
fi
