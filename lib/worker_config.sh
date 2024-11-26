# Paths for configurations
BUILT_IN_CONFIG="/etc/worker/worker.yml"
USER_CONFIG="/home/udx/.cd/configs/worker.yml"
MERGED_CONFIG="/home/udx/.cd/configs/merged_worker.yml"

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
