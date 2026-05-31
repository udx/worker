#!/bin/bash

# Source test helpers
# shellcheck source=../test_helpers.sh disable=SC1091
source "/home/udx/test/test_helpers.sh"

# Test environment commands
print_header "Environment Tests"

# Get environment variables from config
print_info "Getting environment variables from config"
CONFIG_ENV=$(worker config show --format json | jq -r '.config.env | keys[]')
if [ -z "$CONFIG_ENV" ]; then
    print_error "No environment variables found in config"
    exit 1
fi

# Test environment show
print_info "Testing: env show"
ENV_OUTPUT=$(worker env show)
for var in $CONFIG_ENV; do
    if ! echo "$ENV_OUTPUT" | grep -q "$var="; then
        print_error "env show missing variable: $var"
        exit 1
    fi
done

# Test environment set/get
print_info "Testing: env set/get"
worker env set TEST_VAR "test value"
if ! worker env show | grep -q "TEST_VAR=test value"; then
    print_error "env set/get not working"
    exit 1
fi

# Test environment JSON output
print_info "Testing: env show --format json"
JSON_OUTPUT=$(worker env show --format json)
for var in $CONFIG_ENV; do
    if ! echo "$JSON_OUTPUT" | jq -e --arg var "$var" 'has($var)' > /dev/null; then
        print_error "JSON output missing variable: $var"
        exit 1
    fi
done

# Test environment reload
print_info "Testing: env reload"
if ! worker env reload; then
    print_error "env reload should re-apply current configuration"
    exit 1
fi

# All tests passed
print_success "All environment tests passed"
