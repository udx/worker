#!/bin/bash

# Test environment commands

# Test environment show
echo "Testing: env show"
worker env show
if ! worker env show | grep "Environment variables"; then
    echo "FAIL: env show should display environment variables"
    exit 1
fi

# Test environment set/get
echo "Testing: env set/get"
worker env set TEST_VAR "test value"
if ! worker env show | grep "TEST_VAR=test value"; then
    echo "FAIL: env set/get not working"
    exit 1
fi

# Test environment JSON output
echo "Testing: env show --format json"
if ! worker env show --format json | jq -e '.variables'; then
    echo "FAIL: JSON output not working"
    exit 1
fi

# All tests passed
echo "Environment tests passed"
