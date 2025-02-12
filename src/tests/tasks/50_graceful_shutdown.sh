#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Verify that service tests have passed
verify_service_tests() {
    local test_name="Service Tests"
    
    # Check if service test status file exists and indicates success
    if [ ! -f "/tmp/service_tests_passed" ]; then
        log_error "$test_name" "Service tests (40_services.sh) must pass before running graceful shutdown tests"
        return 1
    fi
    log_success "$test_name" "Service tests verified"
    return 0
}

# Test graceful shutdown handling
test_graceful_shutdown() {
    local test_name="Graceful Shutdown"
    
    # First verify service tests have passed
    if ! verify_service_tests; then
        return 1
    fi
    
    log_info "$test_name: Test graceful shutdown of services"
    
    # Start the long-running service defined in services.yaml
    worker service start test_service
    sleep 5
    
    # Check if service is running
    if ! worker service status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Service failed to start"
        return 1
    fi
    log_success "$test_name" "Service started successfully"
    
    # Stop the service
    worker service stop test_service
    
    # Wait for graceful shutdown (should take about 5 seconds based on our test service)
    sleep 7
    
    # Check if service has stopped
    if worker service status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Service did not exit gracefully within timeout"
        return 1
    fi
    log_success "$test_name" "Service exited gracefully"
    
    # Check service logs for proper shutdown sequence
    if ! worker service logs test_service | grep -q "Starting cleanup..."; then
        log_error "$test_name" "Service did not initiate cleanup"
        return 1
    fi
    log_success "$test_name" "Service cleanup initiated"
    
    if ! worker service logs test_service | grep -q "Cleanup completed"; then
        log_error "$test_name" "Service did not complete cleanup"
        return 1
    fi
    log_success "$test_name" "Service cleanup completed"
    
    log_success "$test_name" "Service shut down gracefully"
    return 0
}

# Run the test
test_graceful_shutdown
