#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/test/test_helpers.sh"

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

# Validate expected service names exist in JSON output
EXPECTED_SERVICES="10-long-running 20-clean-exit 30-syntax-error 40-connection-error 50-rapid-exit"
CONFIG_JSON=$(worker service config --format json 2>&1)
for svc in $EXPECTED_SERVICES; do
    if ! echo "$CONFIG_JSON" | jq -e --arg svc "$svc" '.content.services[] | select(.name == $svc) | .name' > /dev/null; then
        print_error "service config missing expected service: $svc"
        exit 1
    fi
done

# All tests passed
print_success "All service tests passed"
