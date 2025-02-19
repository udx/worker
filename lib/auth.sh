#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh

# Array to track configured providers
declare -a configured_providers=()

# Function to get env var names for a provider from config
get_provider_env_vars() {
    local provider=$1
    local config
    config=$(load_and_parse_config)
    
    # Get all env var names from actor creds that match ${VAR} pattern
    if echo "$config" | jq -e '.config.actors' >/dev/null 2>&1; then
        echo "$config" | jq -r ".config.actors[] | select(.type | startswith(\"$provider\")) | .creds" 2>/dev/null | \
        grep -o '\${[^}]*}' | sed 's/[\${}]//g' || true
    fi
}

# Function to check if a provider is configured
is_provider_configured() {
    local provider=$1
    
    # Get all possible env var names from config
    local env_vars
    mapfile -t env_vars < <(get_provider_env_vars "$provider")
    
    # First check all possible env vars
    for env_var in "${env_vars[@]}"; do
        if [ -n "${!env_var}" ]; then
            return 0
        fi
    done
    
    # Fallback to config if no env vars are set
    local config
    config=$(load_and_parse_config)
    
    # Check if we have a valid config with actors
    if echo "$config" | jq -e '.config.actors' >/dev/null 2>&1; then
        # Get all actors for this provider
        local actors
        actors=$(echo "$config" | jq -r ".config.actors[] | select(.type | startswith(\"$provider-\"))" 2>/dev/null)
        
        if [ -n "$actors" ] && [ "$actors" != "null" ]; then
            # Check each actor's credentials
            while IFS= read -r actor; do
                [ -z "$actor" ] && continue
                
                local creds
                creds=$(echo "$actor" | jq -r '.creds' 2>/dev/null)
                [ "$creds" = "null" ] && continue
                
                # Evaluate creds as a reference to an environment variable
                if [[ "$creds" =~ ^\$\{(.+)\}$ ]]; then
                    local env_var_name="${BASH_REMATCH[1]}"
                    creds="${!env_var_name}"
                fi
                
                # If we find any valid credentials, return success
                if [ -n "$creds" ]; then
                    return 0
                fi
            done <<< "$actors"
        fi
    fi
    
    return 1
}

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
            log_success "Authentication" "Detected credentials for $type"
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
            log_error "Authentication" "Credentials format not recognized for $provider. Skipping..."
            continue
        fi
        
        # Proceed only if creds are valid JSON
        if echo "$creds" | jq empty &>/dev/null; then
            log_info "Processing credentials for $provider"
            auth_script="${WORKER_LIB_DIR}/auth/${provider}.sh"
            auth_function="${provider}_authenticate"
            
            if [[ -f "$auth_script" ]]; then
                source "$auth_script"
                
                if command -v "$auth_function" > /dev/null; then
                    
                    if ! authenticate_provider "$provider" "$auth_function" "$creds"; then
                        log_error "Authentication" "Authentication failed for provider $provider."
                        return 1
                    fi
                    configured_providers+=("$provider")
                else
                    log_error "Authentication" "Authentication function $auth_function not found for $provider. Skipping..."
                    continue
                fi
            else
                log_error "Authentication" "Authentication script $auth_script not found for $provider. Skipping..."
                continue
            fi
        else
            log_error "Authentication" "Invalid JSON credentials for $provider. Skipping..."
            continue
        fi
    done
    
    if [[ ${#configured_providers[@]} -eq 0 ]]; then
        log_info "No providers creds detected."
    fi
    
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
    
    return 0
}

# Example usage:
# authenticate_actors "$actors_json"