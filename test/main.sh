#!/bin/bash

# Main test entrypoint that runs inside the container

# Source test helpers
# shellcheck source=./test_helpers.sh disable=SC1091
source "/home/udx/test/test_helpers.sh"

# Exit on any error
set -e

# Initialize test environment
print_header "Setting up test environment"

# Setup test config and examples
CONFIG_DIR=/home/udx/.config/worker

# Create necessary directories
mkdir -p "$CONFIG_DIR"

# Config files are already mounted at the right locations by the Makefile

# Export test environment variables
export TEST_CONFIG_DIR=/home/udx/.config/worker
export TEST_CONFIG_FILE="$TEST_CONFIG_DIR/worker.yaml"

# Counter for test results
TOTAL=0
PASSED=0
FAILED=0

# Directory containing test files
TEST_DIR="/home/udx/test"
cd "$TEST_DIR"

# Don't exit on test failures
set +e

# Run test modules in numeric order
for test_file in modules/[0-9]*.sh; do
    # Skip if no files found
    [ -e "$test_file" ] || continue

    # Extract just the filename
    test_name=$(basename "$test_file")
    
    print_header "Running $test_name"
    TOTAL=$((TOTAL + 1))
    
    # Run test and capture all output
    TEST_OUTPUT=$($test_file 2>&1)
    TEST_RESULT=$?
    
    if [ $TEST_RESULT -eq 0 ]; then
        print_success "$test_name passed"
        PASSED=$((PASSED + 1))
        # Show test output even on success
        echo "$TEST_OUTPUT"
    else
        print_error "$test_name failed (exit code: $TEST_RESULT)"
        print_error "Test output:"
        echo "$TEST_OUTPUT"
        FAILED=$((FAILED + 1))
    fi
    
    echo # Add blank line between tests
done

# Exit with error if any test failed
[ $FAILED -eq 0 ]

# Print summary
print_header "Test Summary"
if [ "$FAILED" -eq 0 ]; then
    print_success "All $TOTAL tests passed successfully"
else
    print_error "$FAILED of $TOTAL tests failed"
    printf "${GREEN}Passed: %d${NC}\n" "$PASSED"
    printf "${RED}Failed: %d${NC}\n" "$FAILED"
fi

# Exit with failure if any tests failed
[ "$FAILED" -eq 0 ] || exit 1
