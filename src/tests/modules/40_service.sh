#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/tests/test_helpers.sh"

# Test service commands
print_header "Service Tests"

# Test service list
print_info "Testing: service list"
SERVICE_OUTPUT=$(worker service list 2>&1)

# Check that we get some output
if [ -z "$SERVICE_OUTPUT" ]; then
    print_error "service list produced no output"
    exit 1
fi

# Test service list json format
print_info "Testing: service list --format json"
LIST_JSON=$(worker service list --format json 2>&1)
if ! echo "$LIST_JSON" | jq -e '.services' > /dev/null; then
    print_error "service list json should include services array"
    exit 1
fi

# Test service config
print_info "Testing: service config"
CONFIG_OUTPUT=$(worker service config 2>&1)

# Check that we get some output
if [ -z "$CONFIG_OUTPUT" ]; then
    print_error "service config produced no output"
    exit 1
fi
if echo "$STATUS_OUTPUT" | grep -q "Simple service is running"; then
    print_error "service should be stopped"
    exit 1
fi

# All tests passed
print_success "All service tests passed"
