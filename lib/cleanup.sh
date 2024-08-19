#!/bin/bash

# Function to cleanup Azure authentication
cleanup_azure() {
    echo "[INFO] Cleaning up Azure authentication"
    az logout
}

# Function to cleanup GCP authentication
cleanup_gcp() {
    echo "[INFO] Cleaning up GCP authentication"
    gcloud auth revoke --all
}

# Function to cleanup AWS authentication
cleanup_aws() {
    echo "[INFO] Cleaning up AWS authentication"
    # Example: If using AWS CLI v2, this is a placeholder for AWS logout
    # aws sso logout
}

# Function to cleanup Bitwarden authentication
cleanup_bitwarden() {
    echo "[INFO] Cleaning up Bitwarden authentication"
    bw logout --force
}

# Function to cleanup actors
cleanup_actors() {
    echo "[INFO] Cleaning up actors"
    
    local WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the configuration file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "[ERROR] YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    local ACTORS_JSON
    ACTORS_JSON=$(yq e -o=json '.config.actors' "$WORKER_CONFIG")
    
    if [ -z "$ACTORS_JSON" ] || [ "$ACTORS_JSON" = "null" ]; then
        echo "[INFO] No actors found for cleanup."
        return 0
    fi

    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while IFS= read -r actor; do
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
                echo "[WARN] Unsupported actor type for cleanup: $type"
            ;;
        esac
    done
}

# Function to cleanup sensitive environment variables
cleanup_sensitive_env_vars() {
    echo "[INFO] Cleaning up sensitive environment variables"
    
    local env_config="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the configuration file exists
    if [ ! -f "$env_config" ]; then
        echo "[ERROR] Configuration file not found at $env_config"
        return 1
    fi
    
    # Extract environment variable names defined in worker.yml (both variables and secrets)
    local defined_vars
    defined_vars=$(yq e -o=json '.config.variables, .config.secrets' "$env_config" | jq -r 'to_entries | map("\(.key)") | .[]')
    
    # Build a regex pattern for sensitive keywords
    local sensitive_keywords="(secret|password|token|key)"
    
    # Find all environment variables that match the sensitive keywords and are not in defined_vars
    for var in $(env | grep -iE "$sensitive_keywords" | cut -d '=' -f 1); do
        if ! echo "$defined_vars" | grep -q "^$var\$"; then
            unset "$var"
            echo "[INFO] Unset sensitive variable: $var"
        fi
    done
}

# Example of initializing the cleanup process
# Uncomment if needed in your setup
# init_cleanup() {
#     echo "[INFO] Initializing cleanup module"
# }

# Call init_cleanup to initialize the module
# Uncomment if needed
# init_cleanup
