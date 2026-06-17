#!/bin/bash

# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/worker_config.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/secrets.sh"
# shellcheck disable=SC1091
source "${WORKER_LIB_DIR}/runtime_output.sh"

if runtime_output_stdout_enabled; then
    exec 3>&1
    exec 1>&2
    export WORKER_OUTPUT_STDOUT_FD=3
fi

log_info "Welcome to UDX Worker Container. Initializing environment..."

configure_environment || exit 1

emit_runtime_output || exit 1

if runtime_output_stdout_enabled; then
    exec 3>&-
    exit 0
fi

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
