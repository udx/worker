#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

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

# Function to clean up actors based on the providers configured during authentication
cleanup_actors() {
    log_info "Starting cleanup of actors"
    
    # Accept configured providers as arguments
    local configured_providers=('azure' 'gcp' 'aws' 'bitwarden')
    
    # Track if any actual cleanup was performed
    local any_cleanup=false
    
    # Loop through each configured provider only
    for provider in "${configured_providers[@]}"; do
        case "$provider" in
            azure)
                cleanup_provider "az" "az logout" "az account show" "Azure" && any_cleanup=true
            ;;
            gcp)
                cleanup_provider "gcloud" "gcloud auth revoke --all" "gcloud auth list" "GCP" && any_cleanup=true
            ;;
            aws)
                cleanup_provider "aws" "aws sso logout" "aws sso list-accounts" "AWS" && any_cleanup=true
            ;;
            bitwarden)
                cleanup_provider "bw" "bw logout --force" "bw status" "Bitwarden" && any_cleanup=true
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
}

# Example usage
# cleanup_actors
