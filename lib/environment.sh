#!/bin/sh

# Include utility functions, secrets fetching, authentication, and cleanup
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh
. /usr/local/lib/cleanup.sh

# Path to the configuration file and temporary resolved file
config_path="/home/$USER/.cd/configs/worker.yml"
temp_config_path="/tmp/worker.yml.resolved"

# Function to resolve environment variables in the configuration file
resolve_env_in_config() {
    touch "$temp_config_path"

    # Use envsubst to resolve environment variables and write to a temporary file
    envsubst < "$config_path" > "$temp_config_path"
    if [ $? -eq 0 ]; then
        # No need to overwrite the source file, just use the temp file
        echo "[INFO] Resolved configuration written to $temp_config_path"
    else
        echo "[ERROR] Failed to resolve environment variables in the configuration"
        rm "$temp_config_path"
        return 1
    fi
}

# Function to set environment variables from the configuration file
set_env_vars() {
    local env_vars

    # Extract environment variables from the temporary file and export them
    env_vars=$(yq e -o=json '.config.env' "$temp_config_path" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')

    # Check if env_vars is empty
    if [ -z "$env_vars" ]; then
        echo "[ERROR] No environment variables found in the configuration"
        rm "$temp_config_path"
        return 1
    fi

    # Use a loop to export each environment variable
    while IFS= read -r var; do
        eval export "$var"
    done <<< "$env_vars"

    # Clean up temporary file
    rm "$temp_config_path"
}

# Main function to coordinate resolving and setting up the environment
configure_environment() {
    resolve_env_in_config
    set_env_vars

    # Authenticate actors before fetching secrets
    authenticate_actors

    # Fetch secrets using the existing fetch_secrets script
    fetch_secrets

    # Only after authentication and fetching secrets, cleanup actors and sensitive environment variables
    cleanup_actors
    cleanup_sensitive_env_vars
}

# Call the main function to configure the environment
configure_environment
