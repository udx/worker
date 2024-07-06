#!/bin/bash

echo "[INFO] Running main.sh"

# Source the .env file
if [ -f "/home/udx/.cd/.env" ]; then
    echo "[INFO] Loading environment variables from .env file"
    set -a
    source /home/udx/.cd/.env
    set +a
else
    echo "[ERROR] .env file not found"
fi

# Source the required libraries
source /usr/local/lib/auth.sh
source /usr/local/lib/secrets.sh

# Fetch environment configuration from worker.yml
fetch_env_config() {
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"

    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi

    ENV_VARS_JSON=$(yq e -o=json '.config.env' "$WORKER_CONFIG")

    echo "$ENV_VARS_JSON" | jq -c 'to_entries[]' | while read -r env_var; do
        name=$(echo "$env_var" | jq -r '.key')
        value=$(resolve_env_vars "$(echo "$env_var" | jq -r '.value')")

        if [ -n "$value" ]; then
            export "$name=$value"
            echo "[INFO] $name is set to $value"
        else
            echo "[ERROR] Failed to set environment variable $name"
        fi
    done
}

fetch_env_config

# Authenticate actors
authenticate_actors

# Fetch secrets
fetch_secrets

# Verify DOCKER_IMAGE_NAME
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "[ERROR] DOCKER_IMAGE_NAME is not set after sourcing secrets"
else
    echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after sourcing secrets"
fi
