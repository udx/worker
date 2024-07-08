#!/bin/bash

# Source the utilities script
source /usr/local/lib/utils.sh

udx_logo

echo "[INFO] Welcome to UDX Worker Container. Initializing environment..."

# Load environment variables from .udx file if it exists
if [ -f /home/$USER/.cd/.udx ]; then
    echo "[INFO] Loading environment variables from .udx file"
    set -a
    . /home/$USER/.cd/.udx
    set +a
else
    echo "[ERROR] .udx file not found"
fi

# Execute the environment.sh script to set up the environment
source /usr/local/lib/environment.sh

# If there are arguments, execute them
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    # Default command if no arguments are provided
    exec sh -c "echo NodeJS@$(node -v)"
fi
