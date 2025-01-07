#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/lib/utils.sh

udx_logo

log_info "Welcome to UDX Worker Container. Initializing environment..."

# shellcheck disable=SC1091
source /usr/local/lib/environment.sh

handle_services() {
    local cmd_exit_status=$1  # Pass command exit status if any

    if check_active_services; then
        wait_for_services
        log_info "Tailing Supervisor logs to keep the container alive."
        tail -f /var/log/supervisor/supervisord.log
    else
        log_warn "No services are active."
        tail -f /dev/null
    fi
}

check_active_services() {
    log_info "Checking for active or starting services..."
    if supervisorctl status | grep -Eq 'RUNNING|STARTING'; then
        log_info "Active or starting services found."
        return 0
    else
        log_warn "No active or starting services detected."
        return 1
    fi
}

wait_for_services() {
    local attempts=0 max_attempts=10
    log_info "Waiting for services to be fully running..."
    while [ $attempts -lt $max_attempts ]; do
        if supervisorctl status | grep -q "RUNNING"; then
            log_info "All services are now running."
            return 0
        fi
        log_info "Waiting for services to be fully running... (Attempt: $attempts)"
        attempts=$((attempts + 1))
        sleep 5
    done
    log_warn "Services are not fully running after $max_attempts attempts."
    return 1
}

# Main execution path
# Main execution path
if [ "$#" -gt 0 ]; then
    log_info "Executing command: $*"
    
    if [[ "$1" =~ \.sh$ ]]; then
        "$@"  # Execute the provided command
        log_info "Shell script execution completed. Exiting."
        exit 0
    else
        "$@"  # Execute the provided command
        cmd_exit_status=$?

        if [ $cmd_exit_status -eq 0 ]; then
            exit 0
        else
            handle_services $cmd_exit_status
        fi
    fi
else
    handle_services
fi