#!/bin/bash

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    # Run main.sh to setup environment and then execute passed commands
    /home/"${USER}"/bin-modules/main.sh "$@"
else
    # If no arguments are passed, execute the main.sh script
    exec /home/"${USER}"/bin-modules/main.sh
fi
