#!/bin/sh

# Include utility functions, secrets fetching, authentication, and cleanup
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh
. /usr/local/lib/cleanup.sh

# Function to resolve environment variables in the configuration file
resolve_env_in_config() {
    local config_path="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$config_path" ]; then
        echo "[ERROR] Configuration file not found at $config_path"
        return 1
    fi
    
    envsubst < "$config_path" > "${config_path}.resolved"
    mv "${config_path}.resolved" "$config_path"
}

# Function to set environment variables from the configuration
set_env_vars() {
    local config_path="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$config_path" ]; then
        echo "[ERROR] Configuration file not found at $config_path"
        return 1
    fi
    
    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$config_path" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')

    # Use a loop to export each environment variable
    while IFS= read -r var; do
        eval export "$var"
    done <<< "$env_vars"
}

# Main function to coordinate resolving and setting up the environment
configure_environment() {
    resolve_env_in_config
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to resolve environment variables in the configuration"
        exit 1
    fi
    
    set_env_vars
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to set environment variables"
        exit 1
    fi

    authenticate_actors
    fetch_secrets
    cleanup_actors
    cleanup_sensitive_env_vars
}

# Call the main function to configure the environment
configure_environment
