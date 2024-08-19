#!/bin/bash

# Source the utilities script
# shellcheck source=/dev/null
source /usr/local/lib/utils.sh

udx_logo

echo "[INFO] Welcome to UDX Worker Container. Initializing environment..."

# Execute the environment.sh script to set up the environment
# shellcheck source=/dev/null
source /usr/local/lib/environment.sh

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    echo "[INFO] No command provided, the container will run interactively."
    # Add any additional logic here if needed
fi
