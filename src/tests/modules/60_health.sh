#!/bin/bash

# Source test helpers
source "/home/udx/tests/test_helpers.sh"

# Test health check commands
print_header "Health Check Tests"

# Test health status
print_info "Testing: health status"
HEALTH_OUTPUT=$(worker health status 2>&1)

# Check for health check running message
if ! echo "$HEALTH_OUTPUT" | grep -q "Running health check"; then
    print_error "health status should show running message"
    exit 1
fi

# Check for successful completion
if ! echo "$HEALTH_OUTPUT" | grep -q "All health checks passed"; then
    print_error "health status should show successful completion"
    exit 1
fi

# Test health status json format
print_info "Testing: health status --format json"
HEALTH_JSON=$(worker health status --format json 2>&1 | sed -n '/^{/,/^}/p')

# Verify JSON structure
if ! echo "$HEALTH_JSON" | jq -e '.status' > /dev/null; then
    print_error "health status json should include status field"
    exit 1
fi

# Verify health metrics are present
if ! echo "$HEALTH_JSON" | jq -e '.disk.usage_percent' > /dev/null; then
    print_error "health status json should include disk usage"
    exit 1
fi

# All tests passed
print_success "All health check tests passed"
