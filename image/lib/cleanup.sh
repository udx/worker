#!/bin/sh

# Function to cleanup Azure authentication
cleanup_azure() {
    echo "Cleaning up Azure authentication"
    az logout
}

# Function to cleanup GCP authentication
cleanup_gcp() {
    echo "Cleaning up GCP authentication"
    gcloud auth revoke --all
}

# Function to cleanup AWS authentication
cleanup_aws() {
    echo "Cleaning up AWS authentication"
    # Example: If using AWS CLI v2, this is a placeholder for AWS logout
    # aws sso logout
}

cleanup_bitwarden() {
    echo "Cleaning up Bitwarden authentication"
    bw logout --force
}

# Function to cleanup actors
cleanup_actors() {
    echo "Cleaning up actors"
    
    # Check the type of each actor and clean up accordingly
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    echo "Extracted actors JSON: $ACTORS_JSON"
    
    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while read -r actor; do
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
                *)
                    echo "Unsupported actor type for cleanup: $type"
                ;;
        esac
    done
}

# Function to cleanup sensitive environment variables
cleanup_sensitive_env_vars() {
    echo "[INFO] Cleaning up sensitive environment variables"
    
    # Load environment variables from worker.yml
    local env_config="/home/$USER/.cd/configs/worker.yml"
    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi
    
    local defined_vars
    defined_vars=$(yq e -o=json '.config.env' "$env_config" | jq -r 'to_entries | map("\(.key)") | .[]')
    
    # Load variables from .env file
    if [ -f /home/$USER/.cd/.env ]; then
        while IFS= read -r line; do
            var_name=$(echo "$line" | cut -d '=' -f 1)
            # Check if the variable is not defined in worker.yml env section
            if ! echo "$defined_vars" | grep -q "^$var_name\$"; then
                unset $var_name
                echo "[INFO] Unset sensitive variable: $var_name"
            fi
        done < /home/$USER/.cd/.env
    else
        echo "[ERROR] .env file not found"
    fi
}

# Initialize the cleanup module
init_cleanup() {
    echo "Initializing cleanup module"
}
