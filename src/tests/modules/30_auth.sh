#!/bin/bash

# Source test helpers
source "/home/udx/tests/test_helpers.sh"

# Test authentication commands
print_header "Authentication Tests"

# Test auth status
print_info "Testing: auth status"

# Capture both stdout and stderr
AUTH_OUTPUT=$(worker auth status 2>&1)

# Test that we got some output
if [ -z "$AUTH_OUTPUT" ]; then
    print_error "auth status produced no output"
    exit 1
fi

# Test that output contains provider status
if ! printf "%s" "$AUTH_OUTPUT" | grep -q "Auth:"; then
    print_error "auth status should show provider status"
    exit 1
fi

# Test auth status json format
print_info "Testing: auth status --format json"
AUTH_JSON=$(worker auth status --format json)
if ! echo "$AUTH_JSON" | jq -e '.[] | select(.provider == "aws") | .status' > /dev/null; then
    print_error "auth status json should include provider status"
    exit 1
fi

# All tests passed
print_success "All authentication tests passed"
