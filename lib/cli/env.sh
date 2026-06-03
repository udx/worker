#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
source "${WORKER_LIB_DIR}/worker_config.sh"
source "${WORKER_LIB_DIR}/secrets.sh"

# Show help for env command
env_help() {
    cat << EOF
Manage environment variables and secrets

Usage: worker env [command]

Available Commands:
  show        Show environment variables
  set         Set an environment variable
  unset       Unset an environment variable
  reload      Reload environment and secrets from configuration
  status      Show environment status
  resolve     Resolve a secret reference value

Options:
  --format    Output format (text/json)
  --filter    Filter variables by prefix
  --include-secrets Include unmasked secrets in output

Examples:
  worker env show                    # Show all environment variables
  worker env show --format json      # Show variables in JSON format
  worker env show --filter AWS_*     # Show only AWS variables
  worker env set MY_VAR "my value"   # Set a new variable
  worker env unset MY_VAR           # Remove a variable
  worker env reload                 # Reload environment and secrets from config
  worker env resolve gcp/my-project/secret # Resolve a secret reference
EOF
}

# Description: Display environment variables with optional filtering
# Options: --format text|json, --filter PATTERN, --include-secrets
# Example: worker env show --format json --filter AWS_* --include-secrets
is_secret_env_name() {
    local name="$1"
    local config

    config=$(load_and_parse_config) || return 1
    echo "$config" | jq -e --arg name "$name" --arg pattern "^(${SUPPORTED_SECRET_PROVIDERS})/.+/.+" '
        (.config.secrets // {} | has($name)) or
        ((.config.env // {} | .[$name] // "" | tostring) | test($pattern))
    ' >/dev/null
}

format_env_value_for_output() {
    local name="$1"
    local include_secrets="$2"
    local value

    if [[ "$include_secrets" != "true" ]] && is_secret_env_name "$name"; then
        printf '%s' '********'
        return 0
    fi

    value=$(get_env_value "$name") || return 1
    printf '%s' "$value"
}

show_environment() {
    local format=${1:-text}
    local filter=${2:-}
    local include_secrets=${3:-false}
    local names

    # Check if environment file exists
    if [ ! -f "$WORKER_ENV_FILE" ]; then
        log_error "Env" "Environment file not found"
        return 1
    fi

    names=$(grep "^export " "$WORKER_ENV_FILE" | cut -d'=' -f1 | cut -d' ' -f2)
    
    case $format in
        json)
            local json="{}"
            while IFS= read -r name; do
                # shellcheck disable=SC2053 # Env filters intentionally support globs like AWS_*.
                if [[ -n "$name" && ( -z "$filter" || "$name" == $filter ) ]]; then
                    local value
                    value=$(format_env_value_for_output "$name" "$include_secrets")
                    json=$(echo "$json" | jq --arg key "$name" --arg value "$value" '. + {($key): $value}')
                fi
            done <<< "$names"
            echo "$json" | jq .
            ;;
        text)
            while IFS= read -r name; do
                # shellcheck disable=SC2053 # Env filters intentionally support globs like AWS_*.
                if [[ -n "$name" && ( -z "$filter" || "$name" == $filter ) ]]; then
                    printf '%s=%s\n' "$name" "$(format_env_value_for_output "$name" "$include_secrets")"
                fi
            done <<< "$names"
            ;;
        *)
            log_error "Env" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Description: Set a new environment variable or update existing one
# Example: worker env set MY_VAR "my value"
set_environment() {
    local name=$1
    local value=$2
    
    if [ -z "$name" ]; then
        log_error "Env" "Variable name is required"
        return 1
    fi
    
    if [ -z "$value" ] && [ "$#" -lt 2 ]; then
        log_error "Env" "Variable value is required"
        return 1
    fi
    
    # Validate variable name
    if ! [[ $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error "Env" "Invalid variable name: $name"
        return 1
    fi
    
    if [ -f "$WORKER_ENV_FILE" ]; then
        upsert_env_value "$name" "$value" || return 1
        export "$name=$value"
        log_success "Env" "Set $name to '$value'"
    else
        log_error "Env" "Environment file not found"
        return 1
    fi
}

# Description: Remove an environment variable
# Example: worker env unset MY_VAR
unset_environment() {
    local name=$1
    
    if [ -z "$name" ]; then
        log_error "Env" "Variable name is required"
        return 1
    fi
    
    # Check if variable exists in environment file
    if grep -q "^export $name=" "$WORKER_ENV_FILE"; then
        # Create a temporary file
        local tmpfile
        tmpfile=$(mktemp)
        
        # Remove the variable from environment file
        grep -v "^export $name=" "$WORKER_ENV_FILE" > "$tmpfile"
        cat "$tmpfile" > "$WORKER_ENV_FILE"
        rm -f "$tmpfile"
        
        # Also remove from current environment
        unset "$name"
        
        log_success "Env" "Unset $name"
        
        # Reload environment to ensure consistency
        source "$WORKER_ENV_FILE"
    else
        log_warn "Env" "Variable $name is not set"
    fi
}



# Description: Validate environment variables against schema
# Options: --format text|json
# Example: worker env validate --format json
validate_environment() {
    local config
    config=$(load_and_parse_config)
    
    if [ -z "$config" ]; then
        log_error "Env" "Failed to load configuration"
        return 1
    fi
    
    # Extract required variables from config
    local required_vars
    required_vars=$(echo "$config" | yq eval '.config.env | keys' -)
    
    local failed=0
    while IFS= read -r var; do
        if [ -z "${!var}" ]; then
            log_error "Env" "Required variable $var is not set"
            failed=1
        fi
    done <<< "$required_vars"
    
    if [ $failed -eq 0 ]; then
        log_success "Env" "All required environment variables are set"
    else
        return 1
    fi
}

# Description: Generate a template environment file
# Options: --file PATH
# Example: worker env template --file .env.template
generate_template() {
    local config
    config=$(load_and_parse_config)
    
    if [ -z "$config" ]; then
        log_error "Env" "Failed to load configuration"
        return 1
    fi
    
    echo "# Worker Environment Variables"
    echo "# Generated on $(date)"
    echo
    
    # Extract variables from config
    echo "$config" | yq eval '.config.env | to_entries | .[] | "# " + .key + "\n" + .key + "=\"" + .value + "\""' -
}

# Description: Reset environment to default values
# Example: worker env reset
reset_environment() {
    # Clear all non-system variables
    local system_vars="HOME|USER|PATH|SHELL|TERM|LANG|PWD"
    
    # Get all variables except system ones
    local vars_to_unset
    vars_to_unset=$(env | grep -vE "^($system_vars)=")
    
    while IFS='=' read -r key _; do
        if [ -n "$key" ]; then
            unset "$key"
        fi
    done <<< "$vars_to_unset"
    
    # Reconfigure environment
    if configure_environment; then
        log_success "Env" "Environment reset to default state"
    else
        log_error "Env" "Failed to reset environment"
        return 1
    fi
}

# Parse command line arguments


# Description: Show environment status and validation results
# Options: --format text|json
# Example: worker env status --format json
show_status() {
    local format=${1:-text}
    
    local env_file_exists=false
    local env_count=0
    
    [ -f "$WORKER_ENV_FILE" ] && env_file_exists=true
    
    if [ "$env_file_exists" = true ]; then
        env_count=$(grep -c "^export" "$WORKER_ENV_FILE" || echo 0)
    fi
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"environment\": {"
                echo "    \"file\": \"$WORKER_ENV_FILE\","
                echo "    \"exists\": $env_file_exists,"
                echo "    \"variables\": $env_count"
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            echo "Environment Status:"
            echo "------------------"
            echo "Environment File: $WORKER_ENV_FILE"
            echo "  - Exists: $env_file_exists"
            echo "  - Variables: $env_count"
            ;;
        *)
            log_error "Env" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Description: Resolve a secret reference value
# Example: worker env resolve gcp/my-project/secret
resolve_secret_ref() {
    local secret_ref="$1"

    if [[ -z "$secret_ref" ]]; then
        log_error "Env" "Secret reference is required"
        return 1
    fi

    # Extract provider and parts from URL
    local provider key_vault_name secret_value
    provider=$(echo "$secret_ref" | cut -d '/' -f 1)
    key_vault_name=$(echo "$secret_ref" | cut -d '/' -f 2)
    secret_value=$(echo "$secret_ref" | cut -d '/' -f 3)

    if [[ -z "$provider" || -z "$key_vault_name" || -z "$secret_value" ]]; then
        log_error "Env" "Invalid secret reference format. Expected: provider/vault/secret"
        return 1
    fi

    # Source the provider module
    source_provider_module "$provider"

    # Resolve the secret
    local resolve_function="resolve_${provider}_secret"
    if command -v "$resolve_function" > /dev/null; then
        local value
        value=$("$resolve_function" "$key_vault_name" "$secret_value")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        else
            log_error "Env" "Failed to resolve secret value"
            return 1
        fi
    else
        log_error "Env" "No resolver found for provider: $provider"
        return 1
    fi
}

# Handle environment commands
env_handler() {
    local cmd=$1
    shift
    
    # Store original arguments for set/unset commands
    local orig_args=("$@")
    
    # Default values
    local format="text"
    local filter=""
    local include_secrets="false"
    
    # Parse arguments for show/status commands
    if [[ "$cmd" == "show" || "$cmd" == "status" ]]; then
        while [[ $# -gt 0 ]]; do
            case $1 in
                --format=*|--type=*)
                    format="${1#*=}"
                    shift
                    ;;
                --format|--type)
                    if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                        format="$2"
                        shift 2
                    else
                        shift
                    fi
                    ;;
                --filter=*)
                    filter="${1#*=}"
                    shift
                    ;;
                --filter)
                    if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                        filter="$2"
                        shift 2
                    else
                        shift
                    fi
                    ;;
                --include-secrets)
                    include_secrets="true"
                    shift
                    ;;
                *)
                    shift
                    ;;
            esac
        done
    fi
    
    case $cmd in
        show)
            show_environment "$format" "$filter" "$include_secrets"
            ;;
        set)
            set_environment "${orig_args[0]}" "${orig_args[1]}"
            ;;
        unset)
            unset_environment "$1"
            ;;
        reload)
            log_info "Env" "Reloading environment from configuration..."
            if ! configure_environment; then
                log_error "Env" "Failed to reload environment from configuration"
                return 1
            fi

            log_success "Env" "Environment successfully reloaded from configuration"
            ;;
        status)
            show_status "$format"
            ;;
        help)
            env_help
            ;;
        resolve)
            resolve_secret_ref "$1"
            ;;
        *)
            log_error "Env" "Unknown command: $cmd"
            env_help
            exit 1
            ;;
    esac
}
