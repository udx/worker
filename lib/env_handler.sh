#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Environment file location
WORKER_ENV_FILE="${WORKER_ENV_FILE:-/etc/worker/environment}"

ensure_env_file() {
    local env_dir
    env_dir=$(dirname "$WORKER_ENV_FILE")

    mkdir -p "$env_dir" || {
        log_error "Environment" "Failed to create environment directory: $env_dir"
        return 1
    }

    touch "$WORKER_ENV_FILE" || {
        log_error "Environment" "Failed to create environment file: $WORKER_ENV_FILE"
        return 1
    }

    chmod 600 "$WORKER_ENV_FILE" || {
        log_error "Environment" "Failed to restrict environment file permissions: $WORKER_ENV_FILE"
        return 1
    }
}

upsert_env_value() {
    local name="$1"
    local value="$2"

    if [[ -z "$name" ]]; then
        log_error "Environment" "Variable name not provided"
        return 1
    fi

    if ! [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error "Environment" "Invalid variable name: $name"
        return 1
    fi

    ensure_env_file || return 1

    local tmpfile
    tmpfile=$(mktemp "${WORKER_ENV_FILE}.tmp.XXXXXX") || {
        log_error "Environment" "Failed to create temporary environment file"
        return 1
    }

    grep -v "^export $name=" "$WORKER_ENV_FILE" > "$tmpfile" || true
    printf 'export %s=%q\n' "$name" "$value" >> "$tmpfile"

    mv "$tmpfile" "$WORKER_ENV_FILE" || {
        rm -f "$tmpfile"
        log_error "Environment" "Failed to update environment file"
        return 1
    }

    chmod 600 "$WORKER_ENV_FILE" || {
        log_error "Environment" "Failed to restrict environment file permissions: $WORKER_ENV_FILE"
        return 1
    }
}

# Generate environment file with regular variables
generate_env_file() {
    local config
    config=$(load_and_parse_config)
    
    if [ -z "$config" ]; then
        log_error "Environment" "Failed to load configuration"
        return 1
    fi

    log_info "Environment" "Loading environment variables from configuration"
    
    ensure_env_file || return 1
    
    while IFS= read -r entry; do
        local key value
        key=$(echo "$entry" | jq -r '.key')
        value=$(echo "$entry" | jq -r '.value | tostring')

        if ! printenv "$key" > /dev/null 2>&1; then
            upsert_env_value "$key" "$value" || return 1
        else
            local env_value
            env_value="$(printenv "$key")"
            upsert_env_value "$key" "$env_value" || return 1
            log_info "Environment" "Detected [$key] in container environment - using runtime value instead of config value"
        fi
    done < <(echo "$config" | jq -c '.config.env // {} | to_entries[]')
}

# Internal function to resolve and append secrets
# Parameters:
#   $1 - secrets_json: JSON object of secrets to resolve
#   $2 - respect_deployment_env: if "true", skip secrets that exist in deployment environment
_resolve_and_append_secrets() {
    local secrets_json="$1"
    local respect_deployment_env="${2:-false}"
    local has_failures=false
    
    if [ -z "$secrets_json" ]; then
        log_error "Environment" "No secrets provided"
        return 1
    fi
    
    # Process each secret and resolve it
    while IFS= read -r secret; do
        local name value
        name=$(echo "$secret" | jq -r '.key')
        
        # Check if variable exists in deployment environment (only if respect_deployment_env is true)
        if [[ "$respect_deployment_env" == "true" ]] && printenv "$name" > /dev/null 2>&1; then
            local deploy_value
            deploy_value="$(printenv "$name")"
            if [[ "$deploy_value" =~ ^(${SUPPORTED_SECRET_PROVIDERS})/.+/.+ ]]; then
                log_info "Environment" "Skipping [$name] from config.secrets - will be resolved from deployment environment secret reference"
            else
                log_info "Environment" "Skipping [$name] from config.secrets - using deployment environment static value"
            fi
            continue
        fi
        
        # Create config JSON for resolve_secret_by_name
        local config_json
        config_json="{ \"config\": { \"secrets\": { \"$name\": $(echo "$secret" | jq '.value') } } }"
        
        # Resolve the secret
        if ! value=$(resolve_secret_by_name "$name" "$config_json") || [[ -z "$value" ]]; then
            log_error "Environment" "Failed to resolve secret for $name"
            has_failures=true
        else
            upsert_env_value "$name" "$value" || has_failures=true
            log_success "Environment" "Resolved secret for $name"
        fi
    done < <(echo "$secrets_json" | jq -c 'to_entries[]')
    
    # If any secret failed to resolve, error out
    if [[ "$has_failures" == "true" ]]; then
        log_error "Environment" "Failed to resolve one or more secrets"
        return 1
    fi
    
    log_success "Environment" "Added all resolved secrets to environment file"
}

# Resolve secrets from worker.yaml config.secrets section
# Respects deployment environment - skips secrets that exist in deployment env
append_resolved_secrets() {
    _resolve_and_append_secrets "$1" "true"
}

# Resolve secrets detected in environment variables
# Always resolves - deployment env vars take precedence by being processed here
resolve_env_var_secrets() {
    _resolve_and_append_secrets "$1" "false"
}

# Configure environment from worker.yaml plus runtime secret references.
configure_environment() {
    log_info "Starting environment configuration..."

    local resolved_config
    resolved_config=$(load_and_parse_config)
    if [[ -z "$resolved_config" ]]; then
        log_error "Environment" "Configuration loading failed. Exiting..."
        return 1
    fi

    if ! export_variables_from_config "$resolved_config"; then
        log_error "Environment" "Failed to export variables."
        return 1
    fi

    local secrets
    secrets=$(get_config_section "$resolved_config" "secrets")
    if [[ $? -eq 0 && -n "$secrets" && "$secrets" != "{}" ]]; then
        log_info "Fetching secrets from configuration..."
        if ! fetch_secrets "$secrets"; then
            log_error "Environment" "Failed to fetch secrets."
            return 1
        fi
    else
        log_info "No secrets defined in the configuration."
    fi

    log_info "Checking for secret references in environment variables..."
    if ! fetch_secrets_from_env_vars; then
        log_error "Environment" "Failed to fetch secrets from environment variables."
        return 1
    fi

    load_environment

    log_info "Secure environment setup completed successfully."
}

# Load environment variables and secrets
load_environment() {
    if [ -f "$WORKER_ENV_FILE" ]; then
        # shellcheck source=/dev/null
        source "$WORKER_ENV_FILE"
    else
        log_warn "Environment" "Environment file not found, generating..."
        generate_env_file
        # shellcheck source=/dev/null
        source "$WORKER_ENV_FILE"
    fi
}

# Format environment variables as JSON or text
format_env_vars() {
    local vars=$1
    local format=${2:-text}
    
    case $format in
        json)
            # Convert to JSON
            local json="{"
            while IFS= read -r line; do
                if [[ $line =~ ^export[[:space:]]+([^=]+)=\"([^\"]*)\" ]]; then
                    if [ -n "$json" ] && [ "$json" != "{" ]; then
                        json="$json,"
                    fi
                    key=${BASH_REMATCH[1]}
                    value=${BASH_REMATCH[2]}
                    json="$json\"$key\":\"$value\""
                fi
            done <<< "$vars"
            json="$json}"
            echo "$json" | jq .
            ;;
        text)
            echo "${vars#export }" | tr -d '\"'
            ;;
        *)
            log_error "Environment" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Initialize environment
init_environment() {
    generate_env_file
    load_environment
}

# Update environment when config changes
update_environment() {
    generate_env_file
    load_environment
}

# Get environment variable value
get_env_value() {
    local var_name="$1"
    
    if [ -z "$var_name" ]; then
        log_error "Environment" "Variable name not provided"
        return 1
    fi
    
    if [ -f "$WORKER_ENV_FILE" ]; then
        (
            # shellcheck source=/dev/null
            source "$WORKER_ENV_FILE"
            printenv "$var_name"
        )
    else
        log_error "Environment" "Environment file does not exist"
        return 1
    fi
}

# List all environment variables
list_env_vars() {
    local show_secrets="$1"
    local env_vars=""
    
    if [ -f "$WORKER_ENV_FILE" ]; then
        env_vars=$(grep "^export" "$WORKER_ENV_FILE" | cut -d'=' -f1 | cut -d' ' -f2)
    fi

    if [ "$show_secrets" = "true" ]; then
        log_warn "Environment" "Secrets are stored in the worker environment file; separate secret listing is no longer used."
    fi
    
    if [ -n "$env_vars" ]; then
        echo "Environment Variables:"
        echo "$env_vars"
    fi
    
}
