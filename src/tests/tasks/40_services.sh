#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Test service functionality
test_services() {
    local test_name="Service Tests"
    
    log_info "$test_name: Testing service management functionality"
    
    # Test 1: Check service configuration
    log_info "Testing service configuration..."
    if ! worker service config | grep -q "test_service"; then
        log_error "$test_name" "test_service not found in configuration"
        return 1
    fi
    log_success "$test_name" "Service configuration verified"
    
    # Test 2: Service lifecycle
    log_info "Testing service lifecycle..."
    
    # Start service
    worker service start test_service
    sleep 2
    if ! worker service status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to start service"
        return 1
    fi
    log_success "$test_name" "Service started successfully"
    
    # Stop service
    worker service stop test_service
    sleep 5  # Allow time for graceful shutdown
    if worker service status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to stop service"
        return 1
    fi
    log_success "$test_name" "Service stopped successfully"
    
    # Restart service
    worker service restart test_service
    sleep 2
    if ! worker service status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to restart service"
        return 1
    fi
    log_success "$test_name" "Service restarted successfully"
    
    # Test 3: Service logs
    log_info "Testing service logs..."
    if ! worker service logs test_service | grep -q "Service running..."; then
        log_error "$test_name" "Service logs not found or incorrect"
        return 1
    fi
    log_success "$test_name" "Service logs verified"
    
    # Test 4: Graceful shutdown
    log_info "Testing graceful shutdown..."
    worker service stop test_service
    sleep 1
    
    # Check logs for cleanup
    if ! worker service logs test_service | grep -q "Starting cleanup..."; then
        log_error "$test_name" "Service did not initiate cleanup"
        return 1
    fi
    sleep 5
    if ! worker service logs test_service | grep -q "Cleanup completed"; then
        log_error "$test_name" "Service did not complete cleanup"
        return 1
    fi
    log_success "$test_name" "Service cleanup verified"
    
    log_success "$test_name" "All service tests passed"
    return 0
}

# Run tests
main() {
    # Remove any existing status file
    rm -f /tmp/service_tests_passed
    
    # Run tests
    test_services || exit 1
    
    # Create status file to indicate success
    touch /tmp/service_tests_passed
}

main
