#!/bin/bash

# Source the secrets environment variables
if [ -f /home/$USER/.cd/configs/secrets_env.sh ]; then
    echo "Sourcing /home/$USER/.cd/configs/secrets_env.sh"
    source /home/$USER/.cd/configs/secrets_env.sh
else
    echo "/home/$USER/.cd/configs/secrets_env.sh not found"
fi

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    # Run main.sh to set up the environment and then execute passed commands
    exec /usr/local/bin/main.sh "$@"
else
    # If no arguments are passed, execute the main.sh script
    /usr/local/bin/main.sh
    
    # If an additional entrypoint script exists in the child image, execute it
    if [ -f "$ADDITIONAL_ENTRYPOINT" ]; then
        echo "Executing additional entrypoint logic..."
        "$ADDITIONAL_ENTRYPOINT"
    else
        # Default command if no additional entrypoint or arguments
        exec sh -c "echo NodeJS@$(node -v)"
    fi
fi
