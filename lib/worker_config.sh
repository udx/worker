#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck source=${WORKER_LIB_DIR}/env_handler.sh disable=SC1091
source "${WORKER_LIB_DIR}/env_handler.sh"

# Paths for configurations
BUILT_IN_CONFIG="${WORKER_CONFIG_DIR}/worker.yaml"  # Built-in default config
USER_CONFIG="${HOME}/.config/worker/worker.yaml"    # Optional user config
MERGED_CONFIG="${WORKER_CONFIG_DIR}/worker.merged.yaml"  # Result of merging both configs

# Ensure `yq` is available
if ! command -v yq >/dev/null 2>&1; then
    log_error "Worker configuration" "yq is not installed. Please ensure it is available in the PATH."
    exit 1
fi

# Ensure configuration file exists
ensure_config_exists() {
    local config_path="$1"
    if [[ ! -s "$config_path" ]]; then
        log_error "Worker configuration" "Configuration file not found or empty: $config_path"
        return 1
    fi
}

# Merge built-in and user-provided configurations
merge_worker_configs() {
    # Ensure the merged configuration file exists
    if [ ! -f "$MERGED_CONFIG" ]; then
        touch "$MERGED_CONFIG" || { log_error "Worker configuration" "Failed to create merged configuration file at $MERGED_CONFIG"; return 1; }
    fi

    # Ensure built-in config exists and has actors section
    if ! ensure_config_exists "$BUILT_IN_CONFIG"; then
        log_error "Worker configuration" "Built-in configuration not found"
        return 1
    fi

    # First copy built-in config (with actors) to merged config
    if ! cp "$BUILT_IN_CONFIG" "$MERGED_CONFIG"; then
        log_error "Worker configuration" "Failed to copy built-in configuration"
        return 1
    fi

    # If user config exists, merge env and secrets sections
    if [[ -f "$USER_CONFIG" && -s "$USER_CONFIG" ]]; then
        # Use yq to merge configs, preserving actors from built-in
        if ! yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$MERGED_CONFIG" "$USER_CONFIG" > "${MERGED_CONFIG}.tmp"; then
            log_error "Worker configuration" "Failed to merge configurations"
            return 1
        fi

        # Check if merge was successful
        if [ -s "${MERGED_CONFIG}.tmp" ]; then
            mv "${MERGED_CONFIG}.tmp" "$MERGED_CONFIG"
            return 0
        else
            rm -f "${MERGED_CONFIG}.tmp"
            log_error "Worker configuration" "Failed to merge configurations - empty result"
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
        log_error "Worker configuration" "Failed to parse merged YAML from $MERGED_CONFIG. yq returned an error."
        return 1
    fi

    echo "$json_output"
}

# Export variables from the configuration
export_variables_from_config() {
    local config_json="$1"

    # Extract only environment variables
    local env_vars
    env_vars=$(echo "$config_json" | jq -r '.config.env // empty')

    if [[ -z "$env_vars" ]]; then
        log_info "No environment variables found in the configuration."
        return 0
    fi

    # Generate environment file
    if [[ -n "$env_vars" && "$env_vars" != "null" ]]; then
        log_success "Worker configuration" "Found environment variables in the configuration."
        generate_env_file
    fi

    # Load environment variables
    load_environment
}

# Function to extract a specific section from the JSON configuration
get_config_section() {
    local config_json="$1"
    local section="$2"

    if [[ -z "$config_json" ]]; then
        log_error "Worker configuration" "Empty configuration JSON provided."
        return 1
    fi

    # Attempt to extract the section and handle missing/null cases
    local extracted_section
    if ! extracted_section=$(echo "$config_json" | jq -r ".config.${section} // empty" 2>/dev/null); then
        log_error "Worker configuration" "Failed to parse section '${section}' from configuration."
        return 1
    fi

    echo "$extracted_section"
}