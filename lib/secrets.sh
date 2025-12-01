#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck source=${WORKER_LIB_DIR}/env_handler.sh disable=SC1091
source "${WORKER_LIB_DIR}/env_handler.sh"

# Dynamically source the required provider-specific modules
source_provider_module() {
    local provider="$1"
    local module_path="${WORKER_LIB_DIR}/secrets/${provider}.sh"

    if [[ -f "$module_path" ]]; then
        # Redirect all output to /dev/null during sourcing
        {
            # shellcheck source=${WORKER_LIB_DIR}/secrets/${provider}.sh disable=SC1091
            source "$module_path"
            # Log after sourcing, but don't let it contaminate stdout during secret resolution
            # The > /dev/null ensures no output goes to stdout from this block
            log_info "Loaded module for provider: $provider"
        } > /dev/null
    else
        log_warn "No module found for provider: $provider"
    fi
}

# Fetch secrets and set them as environment variables
fetch_secrets() {
    local secrets_json="$1"

    log_info "Fetching secrets and setting them as environment variables."

    # Exit early if secrets_json is empty, null, or invalid JSON
    if [[ -z "$secrets_json" || "$secrets_json" == "null" ]]; then
        log_info "No worker secrets found in the configuration."
        return 0
    fi

    # Confirm secrets_json is valid JSON before processing
    if ! echo "$secrets_json" | jq empty > /dev/null 2>&1; then
        log_error "Secrets" "Invalid JSON format for secrets configuration."
        return 1
    fi

    # Resolve secrets and append them to environment file
    if ! append_resolved_secrets "$secrets_json"; then
        log_error "Secrets" "Failed to resolve and append secrets"
        return 1
    fi

    # Source the environment file to update current session
    load_environment
}

# Clean up temporary files
clean_up_files() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Cleaned up temporary file: $file"
        else
            log_warn "Temporary file not found for cleanup: $file"
        fi
    done
}

# Resolve a secret value by name from the configuration
resolve_secret_by_name() {
    local secret_name="$1"
    local config_json="$2"

    if [[ -z "$secret_name" ]]; then
        log_error "Secrets" "Secret name is required"
        return 1
    fi

    if [[ -z "$config_json" ]]; then
        log_error "Secrets" "Configuration is required"
        return 1
    fi

    # Extract secrets section
    local secrets
    secrets=$(echo "$config_json" | jq -r '.config.secrets // empty')
    if [[ -z "$secrets" || "$secrets" == "null" ]]; then
        log_error "Secrets" "No secrets found in configuration"
        return 1
    fi

    # Find the secret URL
    local secret_url
    secret_url=$(echo "$secrets" | jq -r ".[\"$secret_name\"] // empty")
    if [[ -z "$secret_url" ]]; then
        log_error "Secrets" "Secret '$secret_name' not found in configuration"
        return 1
    fi

    # Resolve any environment variables in the URL
    secret_url=$(resolve_env_vars "$secret_url")
    if [[ -z "$secret_url" ]]; then
        log_error "Secrets" "Failed to resolve environment variables in URL"
        return 1
    fi

    # Extract provider and parts from URL
    local provider key_vault_name secret_value
    provider=$(echo "$secret_url" | cut -d '/' -f 1)
    key_vault_name=$(echo "$secret_url" | cut -d '/' -f 2)
    secret_value=$(echo "$secret_url" | cut -d '/' -f 3)

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
            log_error "Secrets" "Failed to resolve secret value"
            return 1
        fi
    else
        log_error "Secrets" "No resolver found for provider: $provider"
        return 1
    fi
}

# Function to detect if a value is a secret reference
is_secret_reference() {
    local value="$1"
    
    # Check if value matches pattern: provider/vault/secret
    # Supported providers: gcp, azure, aws, bitwarden
    if [[ "$value" =~ ^(gcp|azure|aws|bitwarden)/.+/.+ ]]; then
        return 0
    fi
    return 1
}

# Function to fetch secrets from environment variables
fetch_secrets_from_env_vars() {
    local processed_vars=()
    local secrets_json="{"
    local first=true
    
    # Helper function to add a secret reference to JSON
    add_secret_to_json() {
        local var_name="$1"
        local var_value="$2"
        
        # Check if the value is a secret reference
        if ! is_secret_reference "$var_value"; then
            return 0
        fi
        
        log_info "Found secret reference in $var_name: $var_value"
        
        # Add to JSON
        if [ "$first" = true ]; then
            first=false
        else
            secrets_json="$secrets_json,"
        fi
        secrets_json="$secrets_json\"$var_name\":\"$var_value\""
    }
    
    # 1. Process environment variables from worker.yaml (in WORKER_ENV_FILE)
    if [[ -f "$WORKER_ENV_FILE" ]]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
            
            # Extract variable name and value
            if [[ "$line" =~ ^export[[:space:]]+([^=]+)=\"([^\"]*)\" ]]; then
                local var_name="${BASH_REMATCH[1]}"
                local var_value="${BASH_REMATCH[2]}"
                
                # Track that we've processed this variable
                processed_vars+=("$var_name")
                
                # Add if it's a secret reference
                add_secret_to_json "$var_name" "$var_value"
            fi
        done < "$WORKER_ENV_FILE"
    fi
    
    # 2. Process deployment environment variables (from container environment)
    while IFS='=' read -r key value; do
        # Skip if already processed from worker config
        if [[ " ${processed_vars[*]} " =~ " ${key} " ]]; then
            continue
        fi
        
        # Skip system/shell variables
        if [[ "$key" =~ ^(HOME|USER|PATH|SHELL|TERM|LANG|PWD|SHLVL|_|PS1|HOSTNAME|UID|GID|OLDPWD|LS_COLORS|DEBIAN_FRONTEND)$ ]]; then
            continue
        fi
        
        # Skip worker internal variables
        if [[ "$key" =~ ^(WORKER_|AZURE_CONFIG_DIR|CLOUDSDK_|AWS_CONFIG_FILE|GCP_CREDS|TZ)$ ]]; then
            continue
        fi
        
        # Add if it's a secret reference
        add_secret_to_json "$key" "$value"
    done < <(env)
    
    # Close JSON
    secrets_json="$secrets_json}"
    
    # If no secrets found, return early
    if [[ "$secrets_json" == "{}" ]]; then
        log_info "No secret references found in environment variables."
        return 0
    fi
    
    # Validate JSON
    if ! echo "$secrets_json" | jq empty > /dev/null 2>&1; then
        log_error "Secrets" "Invalid JSON format for collected secrets"
        return 1
    fi
    
    # Use existing append_resolved_secrets function to resolve and append
    if ! append_resolved_secrets "$secrets_json"; then
        log_error "Secrets" "Failed to resolve secrets from environment variables"
        return 1
    fi
    
    return 0
}

# Example usage:
# fetch_secrets '{"TEST": "gcp/new_relic_api_key"}'
