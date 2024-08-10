#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to authenticate actors
authenticate_actors() {
    local resolved_config
    resolved_config=$(load_and_resolve_worker_config)
    
    if [ $? -ne 0 ]; then
        nice_logs "error" "Failed to load and resolve worker configuration."
        return 1
    fi
    
    local ACTORS_JSON
    ACTORS_JSON=$(get_worker_actors "$resolved_config")

    if [ -z "$ACTORS_JSON" ] || [ "$ACTORS_JSON" = "null" ]; then
        nice_logs "info" "No worker actors found in the configuration"
    else
        echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while IFS= read -r actor; do
            local type provider actor_data auth_script auth_function
            type=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.type')")
            provider=$(echo "$type" | cut -d '-' -f 1)
            actor_data=$(echo "$actor" | jq -c '.value')
            
            auth_script="/usr/local/lib/auth/${provider}.sh"
            auth_function="${provider}_authenticate"
            
            if [ -f "$auth_script" ]; then
                nice_logs "info" "Found authentication script for provider: $provider"
                # shellcheck source=/dev/null
                source "$auth_script"
                if command -v "$auth_function" > /dev/null; then
                    $auth_function "$actor_data"
                else
                    nice_logs "error" "Authentication function $auth_function not found for provider $provider"
                    return 1
                fi
            else
                nice_logs "error" "Authentication script $auth_script not found for provider $provider"
                return 1
            fi
        done
    fi
    
    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
}
