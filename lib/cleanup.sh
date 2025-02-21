#!/bin/bash

# Include worker config utilities first
# shellcheck source=/dev/null
source "${WORKER_LIB_DIR}/worker_config.sh"

# shellcheck source=/dev/null
source "${WORKER_LIB_DIR}/utils.sh"

# Enable actors cleanup by default
ACTORS_CLEANUP=${ACTORS_CLEANUP:-true}

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
    
    # Check if the provider's CLI returns "no credentials" to skip
    if eval "$list_cmd" > /dev/null 2>&1 | grep -q "no credentials"; then
        return 0  # Skip silently if no active sessions are found
    fi
    
    # Check if the output of the list command is empty
    if [ -z "$(eval "$list_cmd" 2> /dev/null)" ]; then
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
            log_error "Cleanup" "Failed to log out of $name: $logout_output"
            return 1
        fi
    else
        log_success "Cleanup" "$name authentication cleaned up successfully."
        cleaned_up=true
    fi
    
    # Return the cleanup status for summary reporting
    if [[ "$cleaned_up" == true ]]; then
        return 0
    else
        return 1
    fi
}

# Function to clean up credential files
cleanup_cred_files() {
    local provider=$1
    local env_var_name="${provider^^}_CREDS"  # Convert to uppercase
    local creds_value="${!env_var_name}"
    
    # Skip if no credentials value found
    if [[ -z "$creds_value" ]]; then
        return 0
    fi
    
    # If the value is a file path and exists, remove it
    if [[ -f "$creds_value" ]]; then
        log_info "Removing credential file for $provider: $creds_value"
        if rm -f "$creds_value"; then
            log_success "Cleanup" "Removed credential file for $provider"
            return 0
        else
            log_error "Cleanup" "Failed to remove credential file for $provider"
            return 1
        fi
    fi
    
    return 0
}

# Function to clean up actors based on the providers configured during authentication
cleanup_actors() {
    # Check if cleanup is enabled
    if [[ "${ACTORS_CLEANUP,,}" != "true" ]]; then
        log_info "Actors cleanup is disabled via ACTORS_CLEANUP environment variable"
        return 0
    fi

    # Skip cleanup if no providers were configured during authentication
    if [[ ${#configured_providers[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "Starting cleanup of actors"
    
    # Track if any actual cleanup was performed
    local any_cleanup=false
    
    # Only clean up providers that were actually configured
    for provider in "${configured_providers[@]}"; do
        # First cleanup any credential files
        if cleanup_cred_files "$provider"; then
            any_cleanup=true
        fi
        
        # Then cleanup provider sessions
        case "$provider" in
            azure)
                if cleanup_provider "az" "az logout" "az account show" "Azure"; then
                    any_cleanup=true
                fi
                ;;
            gcp)
                if cleanup_provider "gcloud" "gcloud auth revoke --all" "gcloud auth list" "GCP"; then
                    any_cleanup=true
                fi
                ;;
            aws)
                if cleanup_provider "aws" "aws sso logout" "aws sso list-accounts" "AWS"; then
                    any_cleanup=true
                fi
                ;;
            bitwarden)
                if cleanup_provider "bw" "bw logout --force" "bw status" "Bitwarden"; then
                    any_cleanup=true
                fi
                ;;
            *)
                log_warn "Unsupported or unavailable actor type for cleanup: $provider"
                ;;
        esac
    done
    
    # Log a summary if no cleanup actions were needed
    if [[ "$any_cleanup" == false ]]; then
        log_info "No active sessions found for any configured providers."
    fi
    
    # Clear the configured providers array
    configured_providers=()
    
    return 0
}

# Example usage
# cleanup_actors
