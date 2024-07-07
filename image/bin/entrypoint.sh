#!/bin/bash

# Source the utilities script
source /usr/local/lib/utils.sh

udx_logo

echo "[INFO] Welcome to UDX Worker Container. Initializing environment..."

# Load environment variables from .env file if it exists
if [ -f /home/$USER/.cd/.env ]; then
    echo "[INFO] Loading environment variables from .env file"
    set -a
    . /home/$USER/.cd/.env
    set +a
else
    echo "[ERROR] .env file not found"
fi

# Execute the environment.sh script to set up the environment
source /usr/local/lib/environment.sh

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    # If no arguments are passed, check for additional entrypoint logic
    if [ -f "$ADDITIONAL_ENTRYPOINT" ]; then
        echo "Executing additional entrypoint logic..."
        "$ADDITIONAL_ENTRYPOINT"
    else
        # Default command if no additional entrypoint or arguments
        exec sh -c "echo NodeJS@$(node -v)"
    fi
fi
