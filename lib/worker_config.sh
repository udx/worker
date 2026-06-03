#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck source=${WORKER_LIB_DIR}/env_handler.sh disable=SC1091
source "${WORKER_LIB_DIR}/env_handler.sh"

# Paths for configuration.
BUILT_IN_CONFIG="${WORKER_CONFIG_DIR}/worker.yaml"
USER_CONFIG="${HOME}/.config/worker/worker.yaml"

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

# Resolve the runtime configuration path. A mounted user config is preferred;
# otherwise the built-in default keeps the image runnable without mounts.
get_worker_config_path() {
    if [[ -f "$USER_CONFIG" && -s "$USER_CONFIG" ]]; then
        echo "$USER_CONFIG"
        return 0
    fi

    if [[ -f "$BUILT_IN_CONFIG" && -s "$BUILT_IN_CONFIG" ]]; then
        echo "$BUILT_IN_CONFIG"
        return 0
    fi

    echo "$BUILT_IN_CONFIG"
}

# Load and parse the active configuration.
load_and_parse_config() {
    local config_path
    config_path=$(get_worker_config_path)

    if ! ensure_config_exists "$config_path"; then
        return 1
    fi

    local json_output
    if ! json_output=$(yq eval -o=json "$config_path" 2>/dev/null); then
        log_error "Worker configuration" "Failed to parse YAML from $config_path. yq returned an error."
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
