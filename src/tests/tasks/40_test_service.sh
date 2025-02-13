#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

log_info "Test" "Starting service tests..."

# Test 1: Check service configuration
log_info "Test" "Testing service configuration..."
if ! worker service config | grep -q "test_service"; then
    log_error "Test" "Service configuration test failed: test_service not found in config"
    exit 1
fi
log_success "Test" "Service configuration test passed"

# Test 2: Check service list and wait for it to be running
log_info "Test" "Testing service list and waiting for service to be ready..."

# Wait for up to 30 seconds for the service to be fully running
for i in {1..30}; do
    status_output=$(worker service list 2>&1)
    if echo "$status_output" | grep "test_service" | grep -q "RUNNING"; then
        log_success "Test" "Service is now running"
        break
    fi
    if [ "$i" -eq 30 ]; then
        log_error "Test" "Timeout waiting for service to start"
        log_error "Test" "Current status: $status_output"
        exit 1
    fi
    sleep 1
done
log_success "Test" "Service list test passed"

# Test 3: Check service status
log_info "Test" "Testing service status..."
status_output=$(worker service status test_service)
if ! echo "$status_output" | grep -q "RUNNING"; then
    log_error "Test" "Service status test failed: test_service not running"
    log_error "Test" "Current status: $status_output"
    exit 1
fi
log_success "Test" "Service status test passed"

# Test 4: Test service stop/start
log_info "Test" "Testing service stop..."
worker service stop test_service
sleep 2
if worker service status test_service | grep -q "RUNNING"; then
    log_error "Test" "Service stop test failed: test_service still running"
    exit 1
fi
log_success "Test" "Service stop test passed"

log_info "Test" "Testing service start..."
worker service start test_service
sleep 2
if ! worker service status test_service | grep -q "RUNNING"; then
    log_error "Test" "Service start test failed: test_service not running"
    exit 1
fi
log_success "Test" "Service start test passed"

# Test 5: Check service logs
log_info "Test" "Testing service logs..."

# Wait a bit for the service to initialize after restart
sleep 2

# First check if log file exists
log_file="/var/log/supervisor/test_service.out.log"
if [ ! -f "$log_file" ]; then
    log_error "Test" "Service logs test failed: log file not found at $log_file"
    exit 1
fi

# Try a simple tail command first
if ! tail -n 1 "$log_file" > /dev/null 2>&1; then
    log_error "Test" "Service logs test failed: cannot read log file"
    exit 1
fi

# Now test the worker service logs command with --nostream
if ! worker service logs test_service --lines=1 --nostream > /dev/null 2>&1; then
    log_error "Test" "Service logs test failed: worker service logs command failed"
    exit 1
fi

log_success "Test" "Service logs test passed"

log_success "Test" "All service tests completed successfully"
