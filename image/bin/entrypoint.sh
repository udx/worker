#!/bin/bash

# Execute the main.sh script to set up the environment
/usr/local/bin/main.sh

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
