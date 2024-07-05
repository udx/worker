#!/bin/bash

# Source the environment variables from the .env file
if [ -f /home/udx/.cd/.env ]; then
    echo "[INFO] Loading environment variables"
    set -a
    source /home/udx/.cd/.env
    set +a
fi

# Source the secrets script
if [ -f /usr/local/lib/secrets.sh ]; then
    . /usr/local/lib/secrets.sh
else
    echo "[ERROR] Secrets script not found"
    exit 1
fi

# Fetch secrets
fetch_secrets

# Verify DOCKER_IMAGE_NAME
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "[ERROR] DOCKER_IMAGE_NAME is not set after sourcing secrets"
else
    echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after sourcing secrets"
fi

# Rest of the main.sh logic...
