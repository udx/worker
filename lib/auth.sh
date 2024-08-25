#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Function to authenticate actors
authenticate_actors() {
    local actors_json="$1"  # Expect the extracted actors JSON as a parameter

    if [[ -z "$actors_json" || "$actors_json" == "null" ]]; then
        log_info "No worker actors found in the configuration."
        return 0
    fi
    
    # Process each actor in the configuration
    echo "$actors_json" | jq -c '.[]' | while IFS= read -r actor; do
        local type provider creds auth_script auth_function

        # Extract the type and provider from the actor data
        type=$(resolve_env_vars "$(echo "$actor" | jq -r '.type')")
        provider=$(echo "$type" | cut -d '-' -f 1)
        
        # Extract the credentials from the actor data
        creds=$(echo "$actor" | jq -r '.creds')

        # Try to evaluate the credentials as an environment variable
        creds=$(resolve_env_vars "$creds")
        
        if [[ -z "$creds" || "$creds" == "null" ]]; then
            log_info "Skipping $provider authentication as no credentials were provided."
            continue
        fi
        
        # Determine the authentication script and function to use
        auth_script="/usr/local/lib/auth/${provider}.sh"
        auth_function="${provider}_authenticate"
        
        if [[ -f "$auth_script" ]]; then
            log_info "Found authentication script for provider: $provider"
            # shellcheck source=/dev/null
            source "$auth_script"
            
            if command -v "$auth_function" > /dev/null; then
                log_info "Authenticating with $provider"
                
                # Handle authentication based on provider type
                if ! authenticate_provider "$provider" "$auth_function" "$creds"; then
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

    return 0
}

# Example usage (expects actors JSON to be passed):
# authenticate_actors "$actors_json"
