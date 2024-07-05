#!/bin/bash

echo "[INFO] Running entrypoint.sh"
echo "[INFO] Environment variables before sourcing main.sh:"
env

# Execute the main.sh script to set up the environment
/usr/local/bin/main.sh

# Source environment variables from /tmp/secret_vars.sh if it exists
if [ -f /tmp/secret_vars.sh ]; then
    echo "[INFO] Sourcing secrets from /tmp/secret_vars.sh"
    set -a
    source /tmp/secret_vars.sh
    set +a
fi

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    # Execute passed commands
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
