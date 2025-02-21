#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Dynamically source the required provider-specific modules
source_provider_module() {
    local provider="$1"
    local module_path="${WORKER_LIB_DIR}/secrets/${provider}.sh"

    if [[ -f "$module_path" ]]; then
        # shellcheck source=${WORKER_LIB_DIR}/secrets/${provider}.sh disable=SC1091
        source "$module_path"
        log_info "Loaded module for provider: $provider"
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

    # Create a temporary file to store environment variables
    local secrets_env_file
    secrets_env_file=$(mktemp /tmp/secret_vars.XXXXXX)
    echo "# Secrets environment variables" > "$secrets_env_file"

    # Create a JSON object with the secrets in the format expected by resolve_secret_by_name
    local config_json
    config_json=$(echo "{ \"config\": { \"secrets\": $secrets_json } }")

    # Process each secret in the JSON object
    echo "$secrets_json" | jq -c 'to_entries[]' | while IFS= read -r secret; do
        local name value
        name=$(echo "$secret" | jq -r '.key')

        # Check if the secret has a valid name
        if [[ -z "$name" ]]; then
            log_error "Secrets" "Secret name is missing or empty."
            continue
        fi

        # Resolve the secret value using resolve_secret_by_name
        value=$(resolve_secret_by_name "$name" "$config_json")
        if [[ $? -eq 0 && -n "$value" ]]; then
            echo "export $name=\"$value\"" >> "$secrets_env_file"
            log_success "Secrets" "Resolved secret for $name."
        else
            log_error "Secrets" "Failed to resolve secret for $name."
        fi
    done

    # Source the environment file if it exists
    if [[ -s "$secrets_env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$secrets_env_file"
        set +a
        log_info "Secrets environment variables sourced successfully."
    else
        log_error "Secrets" "No secrets were written to the environment file."
        return 1
    fi

    clean_up_files "$secrets_env_file"
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

# Example usage:
# fetch_secrets '{"TEST": "gcp/new_relic_api_key"}'
