#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh
source ${WORKER_LIB_DIR}/worker_config.sh

# Show help for config command
config_help() {
    cat << EOF
Manage worker configuration

Usage: worker config [command]

Available Commands:
  show        Show current configuration
  edit        Edit configuration in default editor
  validate    Validate configuration files
  locations   Show configuration file locations
  init        Initialize a new configuration file
  diff        Show differences between default and current config

Examples:
  worker config show
  worker config show --format json
  worker config validate
  worker config edit
  worker config locations
  worker config init
EOF
}

# Show current configuration
show_config() {
    local format=${1:-yaml}
    log_info "Config" "Current configuration:"
    
    local config
    config=$(load_and_parse_config)
    
    case $format in
        json)
            echo "$config" | yq eval -o=json '.'
            ;;
        yaml)
            echo "$config"
            ;;
        *)
            log_error "Config" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Edit configuration
edit_config() {
    local config_file="${HOME}/.config/worker/worker.yaml"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$config_file")"
    
    # Create file if it doesn't exist
    if [ ! -f "$config_file" ]; then
        cp "/etc/worker/worker.yaml" "$config_file"
    fi
    
    # Use default editor or fallback to nano
    ${EDITOR:-nano} "$config_file"
    
    # Validate after editing
    if validate_config "$config_file"; then
        log_success "Config" "Configuration updated successfully"
    else
        log_error "Config" "Configuration validation failed after editing"
        return 1
    fi
}

# Validate configuration
validate_config() {
    local config_file=${1:-}
    log_info "Config" "Validating configuration..."
    
    # If no file specified, validate all config files
    if [ -z "$config_file" ]; then
        local files=(
            "/etc/worker/worker.yaml"
            "${HOME}/.config/worker/worker.yaml"
            "/etc/worker/supervisor/supervisord.conf"
        )
        
        local failed=0
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                if ! validate_yaml "$file"; then
                    log_error "Config" "Validation failed for $file"
                    failed=1
                else
                    log_success "Config" "Validation passed for $file"
                fi
            fi
        done
        
        return $failed
    else
        # Validate specific file
        if validate_yaml "$config_file"; then
            log_success "Config" "Configuration is valid"
            return 0
        else
            log_error "Config" "Configuration is invalid"
            return 1
        fi
    fi
}

# Show configuration locations
show_locations() {
    cat << EOF
Configuration Locations:
  System config:     /etc/worker/worker.yaml
  User config:       ${HOME}/.config/worker/worker.yaml
  Supervisor config: /etc/worker/supervisor/supervisord.conf
  Services config:   ${HOME}/.config/worker/services.yaml
EOF
}

# Initialize new configuration
init_config() {
    local config_dir="${HOME}/.config/worker"
    local config_file="$config_dir/worker.yaml"
    
    # Create directory if it doesn't exist
    mkdir -p "$config_dir"
    
    # Don't overwrite existing config without confirmation
    if [ -f "$config_file" ]; then
        log_warn "Config" "Configuration file already exists at $config_file"
        read -r -p "Do you want to overwrite it? [y/N] " response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            log_info "Config" "Initialization cancelled"
            return 0
        fi
    fi
    
    # Copy default config
    cp "/etc/worker/worker.yaml" "$config_file"
    
    if [ -f "$config_file" ]; then
        log_success "Config" "Configuration initialized at $config_file"
    else
        log_error "Config" "Failed to initialize configuration"
        return 1
    fi
}

# Show differences between default and current config
show_diff() {
    local default_config="/etc/worker/worker.yaml"
    local user_config="${HOME}/.config/worker/worker.yaml"
    
    if [ ! -f "$user_config" ]; then
        log_error "Config" "User configuration does not exist at $user_config"
        return 1
    fi
    
    log_info "Config" "Differences between default and current configuration:"
    diff -u "$default_config" "$user_config" || true
}

# Handle config commands
config_handler() {
    local cmd=$1
    shift
    
    case $cmd in
        show)
            show_config "$@"
            ;;
        edit)
            edit_config
            ;;
        validate)
            validate_config "$@"
            ;;
        locations)
            show_locations
            ;;
        init)
            init_config
            ;;
        diff)
            show_diff
            ;;
        help)
            config_help
            ;;
        *)
            log_error "Config" "Unknown command: $cmd"
            config_help
            exit 1
            ;;
    esac
}
