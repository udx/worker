#!/bin/bash

echo "[INFO] Running entrypoint.sh"

echo "
        _|            _   _ |   _  _
__ |_| (_| )( .  \)/ (_) |  |( (- |  __
"

echo -e "[INFO] Welcome to UDX Worker Container. Initializing environment..."

# Execute the main.sh script to set up the environment
/usr/local/bin/main.sh

# Check if DOCKER_IMAGE_NAME is set
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "[ERROR] DOCKER_IMAGE_NAME is not set after sourcing main.sh"
else
    echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after sourcing main.sh"
fi

# Source environment variables from /tmp/secret_vars.sh if it exists
if [ -f /tmp/secret_vars.sh ]; then
    source /tmp/secret_vars.sh
else
    echo "[ERROR] /tmp/secret_vars.sh does not exist"
fi

# Verify DOCKER_IMAGE_NAME again
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "[ERROR] DOCKER_IMAGE_NAME is not set after sourcing secrets"
else
    echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after sourcing secrets"
fi

echo -e "[SUCCESS] Environment configuration completed."

# Execute additional entrypoint logic if specified
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    if [ -f "$ADDITIONAL_ENTRYPOINT" ]; then
        "$ADDITIONAL_ENTRYPOINT"
    else
        exec sh -c "echo NodeJS@$(node -v)"
    fi
fi
