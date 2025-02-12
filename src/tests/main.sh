#!/bin/bash

# Source utils.sh for logging functions
# shellcheck disable=SC1091
source /usr/local/lib/utils.sh

log_info "Main" "Running all test suites"

# Find and execute all test scripts in the tasks directory
for test_script in ./tasks/*.sh; do
    log_info "Running $(basename "$test_script")..."
    if bash "$test_script"; then
        log_success "$(basename "$test_script")" "Test completed successfully"
    else
        log_error "$(basename "$test_script")" "Test failed"
        exit 1
    fi
done

log_success "Main" "All test suites completed successfully"