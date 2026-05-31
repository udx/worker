#!/bin/bash

# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

log_info "Welcome to UDX Worker Container. Initializing environment..."

# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/worker_config.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/secrets.sh"
configure_environment || exit 1

# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/runtime_output.sh"
emit_runtime_output || exit 1

# Start the process manager
log_info "Starting process manager..."
"${WORKER_LIB_DIR}/process_manager.sh" &

# Wait for supervisor to be ready
max_attempts=10
attempt=1
while [ $attempt -le $max_attempts ]; do
    if supervisorctl status >/dev/null 2>&1; then
        break
    fi
    sleep 1
    attempt=$((attempt + 1))
done

# Main execution logic
if [ "$#" -gt 0 ]; then
    # Log the command being executed
    log_info "Executing command: $*"
    # Execute the command passed to the container
    exec "$@"
fi

# Keep the container running
wait
