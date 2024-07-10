#!/bin/sh

# Include utility functions, secrets fetching, authentication, and cleanup
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh
. /usr/local/lib/cleanup.sh

# Function to merge base and child configuration files
merge_configs() {
    local base_config="/home/$USER/.cd/configs/worker.yml"
    local child_config="/usr/src/app/src/configs/worker.yml"
    local merged_config="/home/$USER/.cd/configs/worker_merged.yml"

    if [ -f "$child_config" ]; then
        # Merge base and child configurations using yq
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$base_config" "$child_config" > "$merged_config"
    else
        cp "$base_config" "$merged_config"
    fi
}

# Function to resolve environment variables in the merged configuration
resolve_env_in_config() {
    local merged_config="/home/$USER/.cd/configs/worker_merged.yml"
    local expanded_config="/home/$USER/.cd/configs/worker_expanded.yml"
    envsubst < "$merged_config" > "$expanded_config"
}

# Function to set environment variables from the expanded configuration
set_env_vars() {
    local expanded_config="/home/$USER/.cd/configs/worker_expanded.yml"
    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$expanded_config" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')

    # Use a loop to export each environment variable
    while IFS= read -r var; do
        eval export "$var"
    done <<< "$env_vars"
}

# Main function to coordinate merging, resolving, and setting up the environment
configure_environment() {
    merge_configs
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
