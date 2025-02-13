#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/lib/utils.sh

log_info "Welcome to UDX Worker Container. Initializing environment..."

# shellcheck disable=SC1091
source /usr/local/lib/environment.sh

# shellcheck disable=SC1091
source /usr/local/lib/process_manager.sh

# Start services in background if configured
start_services_if_configured() {
    if should_generate_config; then
        log_info "Services found in configuration. Starting services..."
        configure_and_execute_services
        wait_for_services_ready
        return 0
    fi
    return 1
}

# Main execution logic
if [ "$#" -gt 0 ]; then
    # Start services in background if configured
    start_services_if_configured &
    
    # Execute the provided command in foreground
    log_info "Executing command: $*"
    exec "$@"
else
    # No command provided, check for services
    if start_services_if_configured; then
        # Services started, monitor them
        monitor_services
    else
        log_info "No services configured and no command provided. Container will exit."
        exit 0
    fi
fi