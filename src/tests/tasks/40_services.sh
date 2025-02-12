#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Test service management functionality
test_service_management() {
    local test_name="Service Management"
    
    log_info "$test_name: Test supervisor service management functionality"
    
    # Test 1: Service Configuration
    log_info "Testing service configuration loading..."
    if ! supervisorctl status | grep -q "test_service"; then
        log_error "$test_name" "test_service not found in supervisor configuration"
        return 1
    fi
    
    # Test 2: Service Start
    log_info "Testing service start..."
    supervisorctl start test_service
    sleep 2
    if ! supervisorctl status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to start test_service"
        return 1
    fi
    log_success "$test_name" "Service started successfully"
    
    # Test 3: Service Status
    log_info "Testing service status..."
    if ! supervisorctl status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Service status check failed"
        return 1
    fi
    log_success "$test_name" "Service status check passed"
    
    # Test 4: Service Stop
    log_info "Testing service stop..."
    supervisorctl stop test_service
    sleep 7  # Allow time for graceful shutdown
    if supervisorctl status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to stop test_service"
        return 1
    fi
    log_success "$test_name" "Service stopped successfully"
    
    # Test 5: Service Restart
    log_info "Testing service restart..."
    supervisorctl start test_service
    sleep 2
    supervisorctl restart test_service
    sleep 7  # Allow time for stop and start
    if ! supervisorctl status test_service | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to restart test_service"
        return 1
    fi
    log_success "$test_name" "Service restarted successfully"
    
    # Test 6: Check Service Logs
    log_info "Testing service logging..."
    if ! grep -q "Service running..." /var/log/supervisor/test_service.out.log; then
        log_error "$test_name" "Service logs not found or incorrect"
        return 1
    fi
    log_success "$test_name" "Service logs verified successfully"
    
    # Test 7: Graceful Shutdown
    log_info "Testing graceful shutdown..."
    supervisorctl stop test_service
    sleep 1
    
    # Check for cleanup initiation
    if ! grep -q "Starting cleanup..." /var/log/supervisor/test_service.out.log; then
        log_error "$test_name" "Service did not initiate cleanup on stop"
        return 1
    fi
    log_success "$test_name" "Service cleanup initiated successfully"
    
    # Wait for cleanup to complete
    sleep 6
    if ! grep -q "Cleanup completed" /var/log/supervisor/test_service.out.log; then
        log_error "$test_name" "Service did not complete cleanup"
        return 1
    fi
    log_success "$test_name" "Service cleanup completed successfully"
    
    # Test 8: Multiple Services
    log_info "Testing multiple services..."
    # Start both test and app services
    supervisorctl start all
    sleep 2
    
    # Check if both services are running
    if ! supervisorctl status | grep -q "RUNNING" | wc -l | grep -q "2"; then
        log_error "$test_name" "Failed to run multiple services"
        return 1
    fi
    log_success "$test_name" "Multiple services running successfully"
    
    # Stop all services
    supervisorctl stop all
    sleep 7
    
    # Verify all stopped
    if supervisorctl status | grep -q "RUNNING"; then
        log_error "$test_name" "Failed to stop all services"
        return 1
    fi
    log_success "$test_name" "All services stopped successfully"
    
    log_success "$test_name" "All service management tests passed"
    return 0
}

# Test service configuration
test_service_config() {
    local test_name="Service Configuration"
    
    log_info "$test_name: Test service configuration parsing and validation"
    
    # Test 1: Check service.yaml parsing
    log_info "Testing services.yaml parsing..."
    if [ ! -f "/home/udx/services.yaml" ]; then
        log_error "$test_name" "services.yaml not found"
        return 1
    fi
    log_success "$test_name" "services.yaml found and accessible"
    
    # Test 2: Verify service properties
    log_info "Testing service properties..."
    local service_conf="/etc/supervisor/conf.d/test_service.conf"
    if [ ! -f "$service_conf" ]; then
        log_error "$test_name" "Service configuration not generated"
        return 1
    fi
    log_success "$test_name" "Service configuration file exists"
    
    # Check required properties
    if ! grep -q "program:test_service" "$service_conf"; then
        log_error "$test_name" "Invalid service name configuration"
        return 1
    fi
    log_success "$test_name" "Service name configured correctly"
    
    if ! grep -q "stopsignal=TERM" "$service_conf"; then
        log_error "$test_name" "Invalid stop signal configuration"
        return 1
    fi
    log_success "$test_name" "Stop signal configured correctly"
    
    if ! grep -q "stopwaitsecs=10" "$service_conf"; then
        log_error "$test_name" "Invalid stop wait configuration"
        return 1
    fi
    log_success "$test_name" "Stop wait time configured correctly"
    
    log_success "$test_name" "All service configuration tests passed"
    return 0
}

# Run all tests
main() {
    test_service_config || exit 1
    test_service_management || exit 1
}

main
