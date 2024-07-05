#!/bin/sh

# Function to display the logo animation
show_logo() {
    cat << "EOF"

        _|            _   _ |   _  _
__ |_| (_| )( .  \)/ (_) |  |( (- |  __

EOF
}

# Include utility functions and environment configuration
. /usr/local/lib/utils.sh
. /usr/local/lib/environment.sh

# Display the logo animation
show_logo

nice_logs "info" "Here you go, welcome to UDX Worker Container."
nice_logs "info" "Init the environment..."

configure_environment() {
    nice_logs "info" "Loading environment variables"
    if [ -f /home/$USER/.cd/.env ]; then
        export $(grep -v '^#' /home/$USER/.cd/.env | xargs)
    fi

    nice_logs "info" "Fetching environment configuration"
    local env_config="/home/$USER/.cd/configs/worker.yml"

    if [ ! -f "$env_config" ]; then
        nice_logs "error" "Configuration file not found at $env_config"
        exit 1
    fi

    # Use yq to extract environment variables and handle them correctly
    local env_vars=$(yq e -o=json '.config.env | to_entries[] | .key + "=" + (.value | @sh)' "$env_config" | sed 's/^/export /')

    # Export the environment variables
    eval "$env_vars"

    # Fetch secrets and set them as environment variables
    fetch_secrets

    nice_logs "info" "Environment variables set:"
    env | grep -E 'DOCKER_IMAGE_NAME|AZURE_SUBSCRIPTION_ID|AZURE_TENANT_ID|AZURE_APPLICATION_ID|AZURE_APPLICATION_PASSWORD'
}

configure_environment

nice_logs "success" "Environment configuration completed."
