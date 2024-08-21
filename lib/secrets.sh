#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    log_info "Fetching secrets and setting them as environment variables."
    
    # Load and resolve the worker configuration
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    if [[ $? -ne 0 ]]; then
        log_error "Failed to load and resolve worker configuration."
        return 1
    fi
    
    local secrets_env_file="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > "$secrets_env_file"
    
    # Extract secrets from the configuration
    local secrets_json
    secrets_json=$(echo "$resolved_config" | yq eval -o=json '.config.secrets')

    if [ -z "$secrets_json" ] || [ "$secrets_json" = "null" ]; then
        log_info "No worker secrets found in the configuration."
        clean_up_files "$resolved_config" "$secrets_env_file"
        return 0
    fi

    # Process each secret in the configuration
    echo "$secrets_json" | jq -c 'to_entries[]' | while IFS= read -r secret; do
        local name url value
        name=$(echo "$secret" | jq -r '.key')
        url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")
        
        value=$(resolve_secret "$name" "$url")
        
        if [ -n "$value" ]; then
            echo "export $name=\"$value\"" >> "$secrets_env_file"
            log_info "Resolved secret for $name."
        else
            log_error "Failed to resolve secret for $name."
        fi
    done

    # Source the secrets environment variables
    if [ -f "$secrets_env_file" ]; then
        set -a
        # shellcheck source=/dev/null
        source "$secrets_env_file"
        set +a
        log_info "Secrets environment variables sourced successfully."
    else
        log_error "Secrets environment file not found: $secrets_env_file"
        clean_up_files "$resolved_config" "$secrets_env_file"
        return 1
    fi
    
    # Clean up temporary files
    clean_up_files "$resolved_config" "$secrets_env_file"
}

# Function to clean up temporary files
clean_up_files() {
    for file in "$@"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_info "Cleaned up temporary file: $file"
        fi
    done
}

# Example usage:
# fetch_secrets
