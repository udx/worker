#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/test/test_helpers.sh"

# Test configuration commands
print_header "Configuration Tests"

# Test config show
print_info "Testing: config show"
CONFIG_OUTPUT=$(worker config show)
if ! echo "$CONFIG_OUTPUT" | grep -q "kind: workerConfig"; then
    print_error "config show should display configuration"
    exit 1
fi

# Test config show with format json
print_info "Testing: config show --format json"
CONFIG_JSON=$(worker config show --format json)
if ! echo "$CONFIG_JSON" | jq -e '.config.env' > /dev/null; then
    print_error "config show json format should include env section"
    exit 1
fi

# Test config locations
print_info "Testing: config locations"
if ! worker config locations | grep -q "/home/udx/.config/worker"; then
    print_error "config locations should show config paths"
    exit 1
fi

# Test config apply
print_info "Testing: config apply"
if ! worker config apply; then
    print_error "config apply should re-apply current configuration"
    exit 1
fi

# All tests passed
print_success "All configuration tests passed"
