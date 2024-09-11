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
    
    log_info "Cleaning up $name authentication"
    
    if ! command -v "$provider" > /dev/null; then
        log_warn "$name CLI not found. Skipping $name cleanup."
        return 0
    fi

    if ! eval "$list_cmd" > /dev/null 2>&1; then
        log_info "No active $name accounts or sessions found."
        return 0
    fi

    if ! eval "$logout_cmd"; then
        log_error "Failed to log out of $name"
        return 1
    fi

    log_info "$name authentication cleaned up successfully."
}

# Function to clean up actors based on the worker configuration
cleanup_actors() {
    log_info "Starting cleanup of actors"
    
    local worker_config
    if ! worker_config=$(get_worker_config_path); then
        log_error "Failed to retrieve worker configuration path."
        return 1
    fi

    local actors_json
    actors_json=$(yq e -o=json '.config.actors' "$worker_config" 2>/dev/null)

    if [[ -z "$actors_json" || "$actors_json" == "null" ]]; then
        log_info "No actors found for cleanup."
        return 0
    fi

    # Process each actor type
    echo "$actors_json" | jq -c '.[]' | while IFS= read -r actor; do
        local type creds
        type=$(echo "$actor" | jq -r '.type')
        creds=$(echo "$actor" | jq -r '.creds')

        case "$type" in
            azure)
                cleanup_provider "az" "az logout" "az account show" "Azure"
                ;;
            gcp)
                cleanup_provider "gcloud" "gcloud auth revoke --all" "gcloud auth list" "GCP"
                ;;
            aws)
                cleanup_provider "aws" "aws sso logout" "aws sso list-accounts" "AWS"
                ;;
            bitwarden)
                cleanup_provider "bw" "bw logout --force" "bw status" "Bitwarden"
                ;;
            *)
                log_warn "Unsupported or unavailable actor type for cleanup: $type"
                ;;
        esac
    done
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

# Example usage
# cleanup_actors
# cleanup_sensitive_env_vars
