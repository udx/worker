#!/bin/bash

# Paths for configurations
BUILT_IN_CONFIG="/usr/local/configs/worker.yml"
USER_CONFIG="/home/$USER/worker.yml"
MERGED_CONFIG="/usr/local/configs/merged_worker.yml"

# Utility functions for logging
log_info() {
    echo "[INFO] $1" >&2
}

log_error() {
    echo "[ERROR] $1" >&2
}

# Ensure `yq` is available
if ! command -v yq >/dev/null 2>&1; then
    log_error "yq is not installed. Please ensure it is available in the PATH."
    exit 1
fi

# Ensure configuration file exists
ensure_config_exists() {
    local config_path="$1"
    if [[ ! -s "$config_path" ]]; then
        log_error "Configuration file not found or empty: $config_path"
        return 1
    fi
}

# Merge built-in and user-provided configurations
merge_worker_configs() {
    log_info "Merging worker configurations..."

    # Ensure built-in config exists
    ensure_config_exists "$BUILT_IN_CONFIG" || return 1

    # If a user-provided configuration exists, merge it
    if [[ -f "$USER_CONFIG" ]]; then
        log_info "User configuration detected. Merging with the built-in configuration."

        if ! yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BUILT_IN_CONFIG" "$USER_CONFIG" > "$MERGED_CONFIG"; then
            log_error "Failed to merge configurations. yq returned an error."
            return 1
        fi
    else
        log_info "No user configuration provided. Using built-in configuration only."

        # Copy the built-in configuration to the merged configuration
        if ! cp "$BUILT_IN_CONFIG" "$MERGED_CONFIG"; then
            log_error "Failed to copy built-in configuration to merged configuration."
            return 1
        fi
    fi
}

# Load and parse the merged configuration
load_and_parse_config() {
    merge_worker_configs || return 1

    # Parse the merged configuration into JSON
    local json_output
    if ! json_output=$(yq eval -o=json "$MERGED_CONFIG" 2>/dev/null); then
        log_error "Failed to parse merged YAML from $MERGED_CONFIG. yq returned an error."
        return 1
    fi

    echo "$json_output"
}

# Export variables from the configuration
export_variables_from_config() {
    local config_json="$1"

    log_info "Exporting variables from configuration..."

    # Extract the `variables` section
    local variables
    variables=$(echo "$config_json" | jq -r '.config.env // empty')
    if [[ -z "$variables" || "$variables" == "null" ]]; then
        log_info "No variables found in the configuration."
        return 0
    fi

    # Iterate over variables and export them into the main shell
    while IFS="=" read -r key value; do
        eval "export $key=\"$value\""
    done < <(echo "$variables" | jq -r 'to_entries[] | "\(.key)=\(.value)"')
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
    if ! extracted_section=$(echo "$config_json" | jq -r ".config.${section} // empty" 2>/dev/null); then
        log_error "Failed to parse section '${section}' from configuration."
        return 1
    fi

    echo "$extracted_section"
}