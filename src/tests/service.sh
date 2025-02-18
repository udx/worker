#!/bin/bash

# Test service commands

# Test service list
echo "Testing: service list"
if ! worker service list | grep "Available services"; then
    echo "FAIL: service list should show available services"
    exit 1
fi

# Test service status
echo "Testing: service status"
if ! worker service status | grep "Service status"; then
    echo "FAIL: service status not working"
    exit 1
fi

# Test service JSON output
echo "Testing: service list --format json"
if ! worker service list --format json | jq -e '.services'; then
    echo "FAIL: JSON output not working"
    exit 1
fi

# All tests passed
echo "Service tests passed"
