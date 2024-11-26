#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

# Paths for configurations
BUILT_IN_CONFIG="/etc/worker/worker.yml"
USER_CONFIG="/home/udx/.cd/configs/worker.yml"
MERGED_CONFIG="/home/udx/.cd/configs/merged_worker.yml"

# Utility functions for logging
log_info() {
    echo "[INFO] $1"
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
    if [[ ! -f "$config_path" ]]; then
        log_error "Configuration file not found: $config_path"
        return 1
    fi
}

# Merge built-in and user-provided configurations
merge_worker_configs() {
    log_info "Merging worker configurations..."

    # Ensure built-in config exists
    ensure_config_exists "$BUILT_IN_CONFIG" || return 1

    # Ensure target directory exists
    mkdir -p "$(dirname "$MERGED_CONFIG")"

    if [[ -f "$USER_CONFIG" ]]; then
        log_info "User configuration detected. Merging with the built-in configuration."

        # Merge configurations, prioritizing user-provided values
        if ! yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$BUILT_IN_CONFIG" "$USER_CONFIG" > "$MERGED_CONFIG"; then
            log_error "Failed to merge configurations. yq returned an error."
            return 1
        fi
    else
        log_info "No user configuration provided. Using built-in configuration only."
        cp "$BUILT_IN_CONFIG" "$MERGED_CONFIG"
    fi

    log_info "Merged configuration created successfully at $MERGED_CONFIG"
}

# Load and parse the merged configuration
load_and_parse_config() {
    merge_worker_configs || return 1

    # Convert merged YAML to JSON
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

# Debugging helper: Validate JSON structure
validate_json() {
    local json="$1"
    if ! echo "$json" | jq empty 2>/dev/null; then
        log_error "Invalid JSON structure detected."
        return 1
    fi
}

# Example usage (when run as a standalone script)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    log_info "Loading and resolving worker configuration..."
    config_json=$(load_and_parse_config) || exit 1
    validate_json "$config_json" || exit 1
    log_info "Worker configuration loaded successfully."

    # Extract and process additional sections if needed
    # actors=$(echo "$config_json" | jq -r ".actors // empty")
    # secrets=$(echo "$config_json" | jq -r ".secrets // empty")
fi
