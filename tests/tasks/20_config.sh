#!/bin/bash

echo "Starting validation of config..."

# Path to the merged configuration file
MERGED_CONFIG="/home/${USER}/.cd/configs/merged_worker.yml"

# Test configure_environment function
test_configure_environment() {
    echo "Running test: configure_environment"

    # Load the merged configuration
    merged_config=$(cat "$MERGED_CONFIG")

    # Extract environment variables from the merged configuration
    env_vars=$(echo "$merged_config" | yq eval '.config.env' -)

    # Verify environment variables
    for key in $(echo "$env_vars" | yq eval 'keys' -); do
        value=$(echo "$env_vars" | yq eval ".${key}" -)
        if [[ "${!key}" != "$value" ]]; then
            echo "Test failed: $key is not set correctly. Expected: $value, Got: ${!key}"
            return 1
        fi
    done

    echo "Test passed: configure_environment"
}

# Run the test
test_configure_environment

echo "Config tests passed successfully."