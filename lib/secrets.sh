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
    if ! resolved_config=$(load_and_resolve_worker_config); then
        log_error "Failed to load and resolve worker configuration."
        return 1
    fi
    
    local SECRETS_ENV_FILE="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > "$SECRETS_ENV_FILE"
    
    # Extract secrets from the configuration
    local SECRETS_JSON
    SECRETS_JSON=$(yq eval '.config.secrets' "$resolved_config")
    
    if [ -z "$SECRETS_JSON" ] || [ "$SECRETS_JSON" = "null" ]; then
        log_info "No worker secrets found in the configuration."
    else
        echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while IFS= read -r secret; do
            local name url value
            name=$(echo "$secret" | jq -r '.key')
            url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")
            
            value=$(resolve_secret "$name" "$url")
            
            if [ -n "$value" ]; then
                echo "export $name=\"$value\"" >> "$SECRETS_ENV_FILE"
                log_info "Resolved secret for $name."
            else
                log_error "Failed to resolve secret for $name."
            fi
        done
        
        # Source the secrets environment variables
        set -a
        if [ -f "$SECRETS_ENV_FILE" ]; then
            # shellcheck source=/dev/null
            source "$SECRETS_ENV_FILE"
        else
            log_error "No secrets environment file found at: $SECRETS_ENV_FILE"
            return 1
        fi
        set +a
    fi
    
    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
    rm -f "$SECRETS_ENV_FILE"
}
