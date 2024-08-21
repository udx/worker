#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh
# shellcheck source=/dev/null
source /usr/local/lib/worker_config.sh

# Function to clean up Azure authentication
cleanup_azure() {
    log_info "Cleaning up Azure authentication"
    if command -v az > /dev/null; then
        if ! az account show > /dev/null 2>&1; then
            log_info "No active Azure accounts found."
        else
            az logout || log_error "Failed to log out of Azure"
        fi
    else
        log_warn "Azure CLI not found. Skipping Azure cleanup."
    fi
}

# Function to clean up GCP authentication
cleanup_gcp() {
    log_info "Cleaning up GCP authentication"
    if command -v gcloud > /dev/null; then
        if ! gcloud auth list --format="value(account)" > /dev/null 2>&1; then
            log_info "No active GCP accounts found."
        else
            gcloud auth revoke --all || log_error "Failed to revoke GCP authentication"
        fi
    else
        log_warn "GCP CLI not found. Skipping GCP cleanup."
    fi
}

# Function to clean up AWS authentication
cleanup_aws() {
    log_info "Cleaning up AWS authentication"
    if command -v aws > /dev/null; then
        if aws sso list-accounts > /dev/null 2>&1; then
            aws sso logout || log_warn "AWS SSO logout not configured or failed"
        else
            log_info "No active AWS SSO sessions found."
        fi
    else
        log_warn "AWS CLI not found. Skipping AWS cleanup."
    fi
}

# Function to clean up Bitwarden authentication
cleanup_bitwarden() {
    log_info "Cleaning up Bitwarden authentication"
    if command -v bw > /dev/null; then
        if bw status > /dev/null 2>&1; then
            bw logout --force || log_error "Failed to log out of Bitwarden"
        else
            log_info "No active Bitwarden sessions found."
        fi
    else
        log_warn "Bitwarden CLI not found or cannot be executed. Skipping Bitwarden cleanup."
    fi
}

# Function to clean up actors
cleanup_actors() {
    log_info "Starting cleanup of actors"
    
    local worker_config
    worker_config=$(get_worker_config_path)
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to retrieve worker configuration path."
        return 1
    fi
    
    local actors_json
    actors_json=$(yq e -o=json '.config.actors' "$worker_config" 2>/dev/null)
    
    if [ -z "$actors_json" ] || [ "$actors_json" = "null" ]; then
        log_info "No actors found for cleanup."
        return 0
    fi

    # Process each actor in the configuration
    echo "$actors_json" | jq -c '.[]' | while IFS= read -r actor; do
        local type
        type=$(echo "$actor" | jq -r '.type')
        
        local cleanup_function="cleanup_${type//[-]/_}"
        if command -v "$cleanup_function" > /dev/null; then
            $cleanup_function
        else
            log_warn "Unsupported or unavailable actor type for cleanup: $type"
        fi
    done
}

# Function to clean up sensitive environment variables
cleanup_sensitive_env_vars() {
    log_info "Cleaning up sensitive environment variables"
    
    local env_config
    env_config=$(get_worker_config_path)
    
    if [[ $? -ne 0 ]]; then
        log_error "Failed to retrieve configuration path."
        return 1
    fi
    
    # Extract environment variable names defined in worker.yml (both variables and secrets)
    local defined_vars
    defined_vars=$(yq e -o=json '.config.variables, .config.secrets' "$env_config" 2>/dev/null | jq -r 'to_entries[].key')

    if [ -z "$defined_vars" ]; then
        log_info "No sensitive environment variables found."
        return 0
    fi

    # Unset the defined environment variables
    for var in $defined_vars; do
        unset "$var" || log_warn "Failed to unset environment variable: $var"
    done

    log_info "Sensitive environment variables cleaned up successfully."
}

# Example usage:
# cleanup_azure
# cleanup_gcp
# cleanup_aws
# cleanup_bitwarden
# cleanup_actors
# cleanup_sensitive_env_vars
