#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/lib/utils.sh

log_info "Welcome to UDX Worker Container. Initializing environment..."

# shellcheck disable=SC1091
source /usr/local/lib/environment.sh

# Main execution logic
if [ "$#" -gt 0 ]; then
    # Log the command being executed
    log_info "Executing command: $*"
    # Execute the command passed to the container
    exec "$@"
else
    # No command passed, start the process manager
    exec /usr/local/lib/process_manager.sh
fi