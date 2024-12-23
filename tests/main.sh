#!/bin/bash

echo "Running all tests..."

# Find and execute all test scripts in the /usr/local/tests directory
for test_script in /usr/local/tests/tasks/*.sh; do
    echo "Running $(basename "$test_script")..."
    bash "$test_script"
done

echo "All tests completed."