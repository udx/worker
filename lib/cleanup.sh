#!/bin/bash

# Function to log messages
log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warn() {
    echo "[WARN] $1"
}

# Function to clean up Azure authentication
cleanup_azure() {
    log_info "Cleaning up Azure authentication"
    az logout || log_error "Failed to log out of Azure"
}

# Function to clean up GCP authentication
cleanup_gcp() {
    log_info "Cleaning up GCP authentication"
    gcloud auth revoke --all || log_error "Failed to revoke GCP authentication"
}

# Function to clean up AWS authentication
cleanup_aws() {
    log_info "Cleaning up AWS authentication"
    # Example: If using AWS CLI v2, this is a placeholder for AWS logout
    # aws sso logout || log_error "Failed to log out of AWS"
}

# Function to clean up Bitwarden authentication
cleanup_bitwarden() {
    log_info "Cleaning up Bitwarden authentication"
    bw logout --force || log_error "Failed to log out of Bitwarden"
}

# Function to clean up actors
cleanup_actors() {
    log_info "Starting cleanup of actors"
    
    local worker_config="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the configuration file exists
    if [ ! -f "$worker_config" ]; then
        log_error "YAML configuration file not found at $worker_config"
        return 1
    fi
    
    local actors_json
    actors_json=$(yq e -o=json '.config.actors' "$worker_config")
    
    if [ -z "$actors_json" ] || [ "$actors_json" = "null" ]; then
        log_info "No actors found for cleanup."
        return 0
    fi

    # Process each actor in the configuration
    echo "$actors_json" | jq -c 'to_entries[]' | while IFS= read -r actor; do
        local type
        type=$(echo "$actor" | jq -r '.value.type')
        
        case $type in
            azure-service-principal)
                cleanup_azure
            ;;
            gcp-service-account)
                cleanup_gcp
            ;;
            aws-sso)
                cleanup_aws
            ;;
            bitwarden)
                cleanup_bitwarden
            ;;
            *)
                log_warn "Unsupported actor type for cleanup: $type"
            ;;
        esac
    done
}

# Function to clean up sensitive environment variables
cleanup_sensitive_env_vars() {
    log_info "Cleaning up sensitive environment variables"
    
    local env_config="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the configuration file exists
    if [ ! -f "$env_config" ]; then
        log_error "Configuration file not found at $env_config"
        return 1
    fi
    
    # Extract environment variable names defined in worker.yml (both variables and secrets)
    local defined_vars
    defined_vars=$(yq e -o=json '.config.variables, .config.secrets' "$env_config" | jq -r 'to_entries | map("\(.key)") | .[]')
    
    # Build a regex pattern for sensitive keywords
    local sensitive_keywords="(secret|password|token|key)"
    
    # Find and unset all environment variables that match the sensitive keywords and are not in defined_vars
    for var in $(env | grep -iE "$sensitive_keywords" | cut -d '=' -f 1); do
        if ! echo "$defined_vars" | grep -q "^$var\$"; then
            unset "$var"
            log_info "Unset sensitive variable: $var"
        fi
    done
}

# Example of initializing the cleanup process
init_cleanup() {
    log_info "Initializing cleanup module"
    cleanup_actors
    cleanup_sensitive_env_vars
    log_info "Cleanup process completed."
}

# Uncomment to automatically call the cleanup process
# init_cleanup
