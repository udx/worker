#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Array to track configured providers
declare -a configured_providers=()

# Function to authenticate actors
authenticate_actors() {
    local actors_json="$1"  # Expect the extracted actors JSON as a parameter

    if [[ -z "$actors_json" || "$actors_json" == "null" ]]; then
        log_info "No worker actors found in the configuration."
        return 0
    fi
    
    # Use a temporary file to avoid a subshell
    local actors_file
    actors_file=$(mktemp)
    echo "$actors_json" | jq -c '.[]' > "$actors_file"

    # Read all lines into an array, then delete the file
    mapfile -t actors_array < "$actors_file"
    rm -f "$actors_file"

    # Process each actor in the array
    for actor in "${actors_array[@]}"; do
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
                # Add provider to configured list if authentication succeeds
                configured_providers+=("$provider")
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

# Generic function to clean up authentication for any provider
cleanup_provider() {
    local provider=$1
    local logout_cmd=$2
    local list_cmd=$3
    local name=$4
    local cleaned_up=false

    # Check if the provider's CLI is available
    if ! command -v "$provider" > /dev/null; then
        return 0  # Skip silently if CLI is not available
    fi

    # Check if there are active sessions/accounts to clean up
    if ! eval "$list_cmd" > /dev/null 2>&1; then
        return 0  # Skip silently if no active sessions are found
    fi

    log_info "Cleaning up $name authentication"
    
    # Run the logout command and capture any output or errors
    local logout_output
    logout_output=$(eval "$logout_cmd" 2>&1)
    local logout_status=$?

    # Check if the logout was successful or if an expected error message was returned
    if [[ $logout_status -ne 0 ]]; then
        if echo "$logout_output" | grep -q -E "No credentials available to revoke|No active sessions|No active accounts"; then
            log_info "No active $name credentials to revoke."
        else
            log_error "Failed to log out of $name: $logout_output"
            return 1
        fi
    else
        log_info "$name authentication cleaned up successfully."
        cleaned_up=true
    fi

    # Return the cleanup status for summary reporting
    if [[ "$cleaned_up" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Function to clean up sensitive environment variables based on a pattern
cleanup_sensitive_env_vars() {
    log_info "Cleaning up sensitive environment variables"
    
    # Define a pattern for sensitive environment variables (e.g., AZURE_CREDS, GCP_CREDS, etc.)
    local pattern="_CREDS"

    # Loop through environment variables that match the pattern
    for var in $(env | grep "${pattern}" | cut -d'=' -f1); do
        unset "$var"
        log_info "Unset sensitive environment variable: $var"
    done

    log_info "Sensitive environment variables cleaned up successfully."
}

# Example usage:
# authenticate_actors "$actors_json"
# cleanup_actors
# cleanup_sensitive_env_vars
