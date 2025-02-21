#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
source "${WORKER_LIB_DIR}/worker_config.sh"
source "${WORKER_LIB_DIR}/secrets.sh"

# Show help for config command
config_help() {
    cat << EOF
Manage worker configuration

Usage: worker config [command]

Available Commands:
  show        Show current configuration
  edit        Edit configuration in default editor
  locations   Show configuration file locations
  init        Initialize a new configuration file
  diff        Show differences between default and current config
  apply       Parse and apply the configuration
  resolve     Resolve a secret value by name

Examples:
  worker config show
  worker config show --format json
  worker config edit
  worker config locations
  worker config init
EOF
}

# Description: Display current worker configuration
# Options: --format yaml|json
# Example: worker config show --format json
config_show() {
    local format="yaml"
    local args=("$@")
    local i=0
    
    # Parse arguments
    while [ $i -lt ${#args[@]} ]; do
        case "${args[$i]}" in
            --format)
                i=$((i + 1))
                format="${args[$i]}"
                ;;
            *)
                log_error "Config" "Unknown argument: ${args[$i]}"
                return 1
                ;;
        esac
        i=$((i + 1))
    done

    log_info "Config" "Current configuration:"
    
    # Check if user config exists
    if [ ! -f "$USER_CONFIG" ] || [ ! -s "$USER_CONFIG" ]; then
        log_info "Config" "No user configuration found at $USER_CONFIG"
        log_info "Config" "Use 'worker config init' to create one"
        return 0
    fi

    # Parse user config
    local config
    if ! config=$(yq eval -o=json "$USER_CONFIG" 2>/dev/null); then
        log_error "Config" "Failed to parse user configuration"
        return 1
    fi

    # Show config based on format
    case $format in
        json)
            echo "$config"
            ;;
        yaml)
            yq eval "$USER_CONFIG"
            ;;
        *)
            log_error "Config" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Description: Edit configuration in default editor
# Example: worker config edit
edit_config() {
    local config_file="$USER_CONFIG"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    
    # Create file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        # Copy built-in config first to ensure actors section is preserved
        if [ -f "$BUILT_IN_CONFIG" ]; then
            cp "$BUILT_IN_CONFIG" "$config_file" || {
                log_error "Config" "Failed to copy built-in configuration"
                return 1
            }
        else
            # If built-in config doesn't exist, create minimal structure
            cat > "$config_file" << EOF
kind: workerConfig
version: udx.io/worker-v1/config
config: {}
EOF
        fi
    fi
    
    # Use default editor or fallback to nano
    ${EDITOR:-nano} "$config_file"
    
    # Basic YAML validation
    if ! yq eval '.' "$config_file" >/dev/null 2>&1; then
        log_error "Config" "Configuration is invalid YAML"
        return 1
    fi
    
    log_success "Config" "Configuration saved successfully"
    return 0
}



# Description: Display paths of all configuration files
# Example: worker config locations
show_locations() {
    cat << EOF
Configuration Locations:
  Built-in config:   $BUILT_IN_CONFIG
  User config:      $USER_CONFIG
  Merged config:    $MERGED_CONFIG
EOF
}

# Description: Initialize a new configuration file with defaults
# Example: worker config init
init_config() {
    # Skip if config already exists
    if [ -f "$USER_CONFIG" ]; then
        log_info "Config" "Configuration already exists at $USER_CONFIG"
        return 0
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$USER_CONFIG")"
    
    # Create minimal config with timestamp
    cat > "$USER_CONFIG" << EOF
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    CREATED: "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
EOF

    if [ -f "$USER_CONFIG" ]; then
        log_success "Config" "Configuration initialized at $USER_CONFIG"
        merge_worker_configs  # Merge with built-in config
        return 0
    else
        log_error "Config" "Failed to create configuration file"
        return 1
    fi
}

# Description: Show differences between default and current configuration
# Options: --format unified|context|git
# Example: worker config diff --format git
show_diff() {
    # Check if configs exist
    if ! ensure_config_exists "$BUILT_IN_CONFIG"; then
        return 1
    fi
    
    if [ ! -f "$USER_CONFIG" ]; then
        log_error "Config" "User configuration does not exist at $USER_CONFIG"
        return 1
    fi
    
    log_info "Config" "Differences between built-in and user configuration:"
    diff -u "$BUILT_IN_CONFIG" "$USER_CONFIG" || true
}

# Description: Parse and apply the configuration
# Example: worker config apply
apply_config() {
    log_info "Config" "Parsing and applying configuration..."
    
    # Load and parse the configuration
    local config_json
    if ! config_json=$(load_and_parse_config); then
        log_error "Config" "Failed to load and parse configuration"
        return 1
    fi

    # Export variables from the configuration
    if ! export_variables_from_config "$config_json"; then
        log_error "Config" "Failed to export variables from configuration"
        return 1
    fi

    # Extract secrets section from config
    local secrets_json
    secrets_json=$(echo "$config_json" | jq -r '.config.secrets // {}')

    # Fetch and set secrets if any are defined
    if [[ "$secrets_json" != "{}" ]]; then
        if ! fetch_secrets "$secrets_json"; then
            log_error "Config" "Failed to fetch and set secrets"
            return 1
        fi
    fi

    log_success "Config" "Configuration successfully parsed and applied"
    return 0
}

# Description: Resolve a secret value by name
# Example: worker config resolve SECRET_NAME
resolve_secret() {
    local secret_name="$1"

    if [[ -z "$secret_name" ]]; then
        log_error "Config" "Secret name is required"
        return 1
    fi

    # Load and parse the configuration
    local config_json
    config_json=$(load_and_parse_config)
    if [[ -z "$config_json" ]]; then
        log_error "Config" "Failed to load configuration"
        return 1
    fi

    # Use resolve_secret_by_name from secrets.sh
    resolve_secret_by_name "$secret_name" "$config_json"
}

# Handle config commands
config_handler() {
    local cmd=$1
    shift
    
    case $cmd in
        show)
            config_show "$@"
            ;;
        edit)
            edit_config
            ;;
        locations)
            show_locations
            ;;
        apply)
            apply_config
            ;;
        init)
            init_config
            ;;
        diff)
            show_diff
            ;;
        resolve)
            resolve_secret "$@"
            ;;
        help)
            config_help
            ;;
        "")
            config_help
            ;;
        *)
            log_error "Config" "Unknown command: $cmd"
            config_help
            exit 1
            ;;
    esac
}
