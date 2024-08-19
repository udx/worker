#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    nice_logs "info" "Fetching secrets"
    
    local resolved_config
    if ! resolved_config=$(load_and_resolve_worker_config); then
        nice_logs "error" "Failed to load and resolve worker configuration."
        return 1
    fi
    
    SECRETS_ENV_FILE="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > "$SECRETS_ENV_FILE"
    
    local SECRETS_JSON
    if ! SECRETS_JSON=$(get_worker_secrets "$resolved_config"); then
        nice_logs "error" "Failed to get worker secrets."
        return 1
    fi
    
    if [ -z "$SECRETS_JSON" ]; then
        nice_logs "info" "No worker secrets found in the configuration"
    else
        echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while read -r secret; do
            name=$(echo "$secret" | jq -r '.key')
            url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")
            
            value=$(resolve_secret "$name" "$url")
            
            if [ -n "$value" ]; then
                echo "export $name=\"$value\"" >> "$SECRETS_ENV_FILE"
                nice_logs "info" "Secret $name resolved and set as environment variable."
            else
                nice_logs "error" "Failed to resolve secret for $name"
            fi
        done
        
        set -a
        if [ -f "$SECRETS_ENV_FILE" ]; then
            # shellcheck source=/dev/null
            source "$SECRETS_ENV_FILE"
        else
            nice_logs "error" "Secrets environment file not found: $SECRETS_ENV_FILE"
            return 1
        fi
        set +a
    fi
    
    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
}
