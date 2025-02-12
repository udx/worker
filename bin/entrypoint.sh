#!/bin/bash

# shellcheck disable=SC1091
source /usr/local/lib/utils.sh

# Global variable to track if shutdown is in progress
SHUTDOWN_IN_PROGRESS=0

# Signal handlers for graceful shutdown
handle_shutdown() {
    local signal=$1
    
    # Prevent multiple shutdown attempts
    if [ "$SHUTDOWN_IN_PROGRESS" -eq 1 ]; then
        log_info "Shutdown already in progress..."
        return
    fi
    SHUTDOWN_IN_PROGRESS=1
    
    log_info "$signal received - initiating graceful shutdown..."
    
    # Stop supervisor itself gracefully
    if [ -f /var/run/supervisord.pid ]; then
        log_info "Stopping all supervisor services..."
        supervisorctl stop all
        
        # Wait for services to stop (max 30 seconds)
        local timeout=30
        local elapsed=0
        while [ $elapsed -lt $timeout ]; do
            if ! supervisorctl status | grep -Eq 'RUNNING|STOPPING|STARTING'; then
                log_info "All services stopped successfully"
                break
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        if [ $elapsed -eq $timeout ]; then
            log_error "Entrypoint" "Timeout waiting for services to stop"
        fi
        
        # Stop supervisord itself
        log_info "Stopping supervisord..."
        kill -TERM "$(cat /var/run/supervisord.pid)"
        wait "$(cat /var/run/supervisord.pid)" 2>/dev/null || true
    fi
    
    # Kill any remaining child processes
    pkill -P $$
    
    log_info "Shutdown complete"
    exit 0
}

# Set up signal handlers
trap 'handle_shutdown SIGTERM' TERM
trap 'handle_shutdown SIGINT' INT
trap 'handle_shutdown SIGQUIT' QUIT

log_info "Welcome to UDX Worker Container. Initializing environment..."

# shellcheck disable=SC1091
source /usr/local/lib/environment.sh

handle_services() {
    
    if check_active_services; then
        wait_for_services
        log_info "Services are fully running."
    else
        log_warn "Entrypoint" "No services are active. Keeping container alive..."
        exec tail -f /dev/null
    fi
}

check_active_services() {
    log_info "Checking for active or starting services..."
    if supervisorctl status | grep -Eq 'RUNNING|STARTING'; then
        log_info "Active or starting services found."
        return 0
    else
        log_warn "Entrypoint" "No active or starting services detected."
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
    log_warn "Entrypoint" "Services are not fully running after $max_attempts attempts."
    return 1
}

# Initialize signal handlers and prepare environment
log_info "Initializing signal handlers for graceful shutdown..."

# Main execution path
if [ "$#" -gt 0 ]; then
    log_info "Executing command: $*"
    
    if [[ "$1" =~ \.sh$ ]]; then
        # Execute shell scripts in a subshell to maintain signal handling
        ("$@")
        exit_code=$?
        log_info "Shell script execution completed with exit code $exit_code"
        exit "$exit_code"
    else
        handle_services
        # Start the command in background and wait for it
        "$@" &
        command_pid=$!
        wait "$command_pid"
        exit_code=$?
        exit "$exit_code"
    fi
else
    handle_services
    # Keep the script running and wait for signals
    while [ "$SHUTDOWN_IN_PROGRESS" -eq 0 ]; do
        sleep 1
    done
fi