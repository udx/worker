#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to authenticate actors
authenticate_actors() {
    # Load and resolve the worker configuration
    local resolved_config
    if ! resolved_config=$(load_and_resolve_worker_config); then
        log_error "Failed to load and resolve worker configuration."
        return 1
    fi

    # Extract actors from the configuration
    local ACTORS_JSON
    ACTORS_JSON=$(yq eval '.config.actors' "$resolved_config")

    if [ -z "$ACTORS_JSON" ] || [ "$ACTORS_JSON" = "null" ]; then
        log_info "No worker actors found in the configuration."
        return 0
    fi

    # Process each actor in the configuration
    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while IFS= read -r actor; do
        local type provider actor_data auth_script auth_function

        # Extract the type and provider from the actor data
        type=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.type')")
        provider=$(echo "$type" | cut -d '-' -f 1)
        actor_data=$(echo "$actor" | jq -c '.value')

        # Determine the authentication script and function to use
        auth_script="/usr/local/lib/auth/${provider}.sh"
        auth_function="${provider}_authenticate"

        if [ -f "$auth_script" ]; then
            log_info "Found authentication script for provider: $provider"
            # shellcheck source=/dev/null
            source "$auth_script"
            if command -v "$auth_function" > /dev/null; then
                log_info "Authenticating with $provider"
                if ! $auth_function "$actor_data"; then
                    log_error "Authentication failed for provider $provider"
                    return 1
                fi
            else
                log_error "Authentication function $auth_function not found for provider $provider"
                return 1
            fi
        else
            log_error "No authentication script found for provider: $provider"
            return 1
        fi
    done

    # Clean up the temporary resolved config file
    rm -f "$resolved_config"
}
