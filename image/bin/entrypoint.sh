#!/bin/bash

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    # Run main.sh to setup environment and then execute passed commands
    /usr/local/bin/main.sh "$@"
else
    # If no arguments are passed, execute the main.sh script
    exec /usr/local/bin/main.sh
    
    # If an additional entrypoint script exists in the child image, execute it
    if [ -f $ADDITIONAL_ENTRYPOINT ]; then
        echo "Executing additional entrypoint logic..."
        $ADDITIONAL_ENTRYPOINT "$@"
    fi
fi
