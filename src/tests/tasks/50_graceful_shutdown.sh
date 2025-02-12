#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Test graceful shutdown handling
test_graceful_shutdown() {
    local test_name="Graceful Shutdown"
    
    log_info "$test_name: Test graceful shutdown of supervisor processes"
    
    # Start the long-running service defined in services.yaml
    supervisorctl start test_service
    
    # Wait for service to start
    sleep 5
    
    # Check if service is running
    if ! supervisorctl status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Service failed to start"
        return 1
    fi
    log_success "$test_name" "Service started successfully"
    
    # Send SIGTERM to the process
    if [ -f /var/run/supervisord.pid ]; then
        local supervisor_pid=$(cat /var/run/supervisord.pid)
        log_info "$test_name: Sending SIGTERM to supervisord (PID: $supervisor_pid)"
        kill -TERM "$supervisor_pid"
        
        # Wait for graceful shutdown (should take about 5 seconds based on our test service)
        sleep 7
        
        # Check if process has exited gracefully
        if ps -p "$supervisor_pid" > /dev/null 2>&1; then
            log_error "$test_name" "Process did not exit gracefully within timeout"
            return 1
        fi
        log_success "$test_name" "Process exited gracefully"
        
        # Check service logs for proper shutdown sequence
        if ! grep -q "Starting cleanup..." /var/log/supervisor/test_service.out.log; then
            log_error "$test_name" "Service did not initiate cleanup"
            return 1
        fi
        log_success "$test_name" "Service cleanup initiated"
        
        if ! grep -q "Cleanup completed" /var/log/supervisor/test_service.out.log; then
            log_error "$test_name" "Service did not complete cleanup"
            return 1
        fi
        log_success "$test_name" "Service cleanup completed"
        
        log_success "$test_name" "Service shut down gracefully"
        return 0
    else
        log_error "$test_name" "Supervisor PID file not found"
        return 1
    fi
}

# Run the test
test_graceful_shutdown
