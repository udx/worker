#!/bin/bash

# Main test runner for CLI commands

# Set error handling
set -e

# Change to script directory
cd "$(dirname "$0")"

# Make all test files executable
chmod +x ./*.sh

# Counter for test results
TOTAL=0
PASSED=0
FAILED=0

# Run each test file
for test_file in auth.sh config.sh env.sh health.sh sbom.sh service.sh; do
    if [ -f "$test_file" ]; then
        echo "Running tests from $test_file..."
        TOTAL=$((TOTAL + 1))
        
        if ./"$test_file"; then
            echo "✓ $test_file passed"
            PASSED=$((PASSED + 1))
        else
            echo "✗ $test_file failed"
            FAILED=$((FAILED + 1))
        fi
        echo "----------------------------------------"
    fi
done

# Print summary
echo "Test Summary:"
echo "Total: $TOTAL"
echo "Passed: $PASSED"
echo "Failed: $FAILED"

# Exit with failure if any tests failed
[ "$FAILED" -eq 0 ] || exit 1
