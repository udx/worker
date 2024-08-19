#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to authenticate actors
authenticate_actors() {
    local resolved_config
    if ! resolved_config=$(load_and_resolve_worker_config); then
        nice_logs "error" "Failed to load and resolve worker configuration."
        return 1
    fi

    local ACTORS_JSON
    if ! ACTORS_JSON=$(get_worker_actors "$resolved_config"); then
        nice_logs "error" "Failed to get worker actors."
        return 1
    fi

    if [ -z "$ACTORS_JSON" ] || [ "$ACTORS_JSON" = "null" ]; then
        nice_logs "info" "No worker actors found in the configuration"
        return 0
    fi

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
                nice_logs "info" "Authenticating with $provider..."
                if ! $auth_function "$actor_data"; then
                    nice_logs "error" "Failed to authenticate with $provider"
                    return 1
                fi
            else
                nice_logs "error" "Authentication function $auth_function not found for provider $provider"
                return 1
            fi
        else
            nice_logs "error" "Authentication script $auth_script not found for provider $provider"
            return 1
        fi
    done

    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
}
