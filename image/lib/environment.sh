#!/bin/sh

# Include utility functions, secrets fetching, and authentication
. /usr/local/lib/utils.sh
. /usr/local/lib/secrets.sh
. /usr/local/lib/auth.sh

configure_environment() {
    if [ -f /home/$USER/.cd/.env ]; then
        set -a
        . /home/$USER/.cd/.env
        set +a
    fi

    local env_config="/home/$USER/.cd/configs/worker.yml"
    if [ ! -f "$env_config" ]; then
        echo "Error: Configuration file not found at $env_config"
        exit 1
    fi

    local env_vars
    env_vars=$(yq e -o=json '.config.env' "$env_config" | jq -r 'to_entries | map("\(.key)=\(.value | @sh)") | .[]')
    eval $(echo "$env_vars" | envsubst)
    export $(echo "$env_vars" | envsubst | sed "s/'//g")

    authenticate_actors
    fetch_secrets
}

configure_environment
