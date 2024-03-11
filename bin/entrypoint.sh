#!/bin/bash
#
# This is the entry point into the container. It will be the first script that runs when the container starts.
#
# The entrypoint script is responsible for setting up the environment and then executing the command passed to the container.
# This script is also responsible for handling any environment variables and secrets are passed to the container.
#
# ...
# ...
# ...

# Load the utility functions
source "bin/modules/utils.sh"

# Load the environment defaults
env_defaults

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker tool." "info"

nice_logs "..." "info"

sleep 3

nice_logs "[${ENV_TYPE}] Starting the environment." "info"

nice_logs "..." "info"

sleep 3

# Load the environment configuration module
source "bin/modules/${ENV_TYPE}.sh"

nice_logs "[${ENV_TYPE}] The environment has started successfully." "success"

## Command pass-through.
exec "$@"