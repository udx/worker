#!/bin/bash

# Load the utility functions
source "/home/bin/modules/utils.sh"

# Get the module and command from the arguments
MODULE=$1
COMMAND=$2

# Load the environment defaults
env_defaults $MODULE

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker tool." "info"

nice_logs "..."

sleep 3

nice_logs "[${MODULE}] Starting the environment." "info"

nice_logs "..."

sleep 3

# Load the environment configuration module
if [ -f "/home/bin/modules/${MODULE}.sh" ]; then
    source "/home/bin/modules/${MODULE}.sh"
else
    bash -c "$COMMAND"
fi

nice_logs "The [${MODULE}] environment has started successfully." "success"