#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Array to track configured providers
declare -a configured_providers=()

# Function to authenticate actors
authenticate_actors() {
    local actors_json="$1"

    if [[ -z "$actors_json" || "$actors_json" == "null" ]]; then
        log_info "No worker actors found in the configuration."
        return 0
    fi

    local actors_file
    actors_file=$(mktemp)
    echo "$actors_json" | jq -c '.[]' > "$actors_file"

    mapfile -t actors_array < "$actors_file"
    rm -f "$actors_file"

    for actor in "${actors_array[@]}"; do
        local type provider creds auth_script auth_function

        type=$(resolve_env_vars "$(echo "$actor" | jq -r '.type')")
        provider=$(echo "$type" | cut -d '-' -f 1)
        creds=$(echo "$actor" | jq -r '.creds')

        # Evaluate creds as a reference to an environment variable
        if [[ "$creds" =~ ^\$\{(.+)\}$ ]]; then
            local env_var_name="${BASH_REMATCH[1]}"
            creds="${!env_var_name}"
        fi

        # Skip if the credentials are empty or not defined
        if [[ -z "$creds" ]]; then
            continue
        else
            log_info "Detected credentials for $type"
        fi

        # Explicitly check for JSON format
        if echo "$creds" | jq -e . >/dev/null 2>&1; then
            log_info "Reading JSON credentials"
        # Then, check if it's a file path
        elif [[ -f "$creds" ]]; then
            log_info "Reading credentials from file: $creds"
            creds=$(cat "$creds")
        # Finally, check if it's possibly base64 encoded
        elif echo "$creds" | base64 --decode &>/dev/null && echo "$creds" | base64 --decode | jq empty &>/dev/null; then
            log_info "Reading base64 encoded JSON credentials"
            creds=$(echo "$creds" | base64 --decode)
        else
            log_error "Credentials format not recognized for $provider. Skipping..."
            continue
        fi

        # Proceed only if creds are valid JSON
        if echo "$creds" | jq empty &>/dev/null; then
            log_info "Processing credentials for $provider"
            auth_script="/usr/local/lib/auth/${provider}.sh"
            auth_function="${provider}_authenticate"

            if [[ -f "$auth_script" ]]; then
                source "$auth_script"

                if command -v "$auth_function" > /dev/null; then

                    if ! authenticate_provider "$provider" "$auth_function" "$creds"; then
                        log_error "Authentication failed for provider $provider."
                        return 1
                    fi
                    configured_providers+=("$provider")
                else
                    log_error "Authentication function $auth_function not found for $provider. Skipping..."
                    continue
                fi
            else
                log_error "Authentication script $auth_script not found for $provider. Skipping..."
                continue
            fi
        else
            log_error "Invalid JSON credentials for $provider. Skipping..."
            continue
        fi
    done

    return 0
}

# Function to handle provider-specific authentication
authenticate_provider() {
    local provider="$1"
    local auth_function="$2"
    local creds="$3"
    local temp_config_file
    
    # Save the credentials data to a temporary file
    temp_config_file=$(mktemp /tmp/actor_creds.XXXXXX)
    echo "$creds" > "$temp_config_file"
    
    # Ensure cleanup with a trap in case of unexpected exit
    trap 'rm -f "$temp_config_file"' EXIT
    
    # Call the authentication function with the temp file
    if ! $auth_function "$temp_config_file"; then
        log_error "Authentication failed for provider $provider."
        return 1
    fi
    
    # Clean up the temporary file
    rm -f "$temp_config_file"
    trap - EXIT
    
    # Set an environment variable to mark successful authorization
    export "${provider^^}_AUTHORIZED=true"
    log_info "Authorization successful for provider $provider."
    
    return 0
}

# Example usage:
# authenticate_actors "$actors_json"
# cleanup_actors