#!/bin/bash

echo "Starting validation of config..."

# Path to the merged configuration file
MERGED_CONFIG="/usr/local/configs/worker/merged_worker.yaml"

# Test configure_environment function
test_configure_environment() {
    echo "Running test: configure_environment"

    # Load the merged configuration
    merged_config=$(cat "$MERGED_CONFIG")

    # Extract environment variables from the merged configuration
    env_vars=$(echo "$merged_config" | yq eval '.config.env' -)

    # Verify environment variables
    for key in $(echo "$env_vars" | yq eval 'keys' -); do
        # Check if key is empty or not set
        if [[ -z "$key" || "$key" == "null" || "$key" == "-" ]]; then
            continue
        fi

        value=$(echo "$env_vars" | yq eval ".${key}" -)
        actual_value="${!key}"

        if [[ "$actual_value" != "$value" ]]; then
            echo "Test failed: $key is not set correctly. Expected: $value, Got: $actual_value"
            return 1
        else
            echo "Test passed: $key is set correctly."
        fi
    done

    echo "Test passed: configure_environment"
}

# Run the test
if test_configure_environment; then
    echo "Config tests passed successfully."
else
    echo "Config tests failed."
    exit 1
fi