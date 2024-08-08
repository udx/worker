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
    
    # Check the type of each actor and clean up accordingly
    local WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    local ACTORS_JSON
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    
    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while read -r actor; do
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
                echo "Unsupported actor type for cleanup: $type"
            ;;
        esac
    done
}

# Function to cleanup sensitive environment variables
cleanup_sensitive_env_vars() {
    echo "[INFO] Cleaning up sensitive environment variables"
    
    local env_config="/home/$USER/.cd/configs/worker.yml"
    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi
    
    # Extract environment variable names defined in worker.yml (both env and workerSecrets)
    local defined_vars
    defined_vars=$(yq e -o=json '.config.env, .config.workerSecrets' "$env_config" | jq -r 'to_entries | map("\(.key)") | .[]')
    
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

# Initialize the cleanup module
# init_cleanup() {
#     echo "Initializing cleanup module"
# }

# Call init_cleanup to initialize the module
# init_cleanup
