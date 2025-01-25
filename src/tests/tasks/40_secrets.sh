#!/bin/bash

echo "Starting validation of secrets fetching..."

# Path to the merged configuration file
MERGED_CONFIG="/usr/local/configs/worker/merged_worker.yml"

# Test verify_secrets function
test_verify_secrets() {
    echo "Running test: verify_secrets"

    # Load the merged configuration
    merged_config=$(cat "$MERGED_CONFIG")

    # Extract secrets from the merged configuration
    secrets=$(echo "$merged_config" | yq eval '.config.secrets' -)

    # Check if secrets is empty or null
    if [[ -z "$secrets" || "$secrets" == "null" ]]; then
        echo "Info: No secrets found in the configuration."
        return 0
    fi

    # Verify secrets as environment variables
    for secret_key in $(echo "$secrets" | yq eval 'keys' -); do

        # Check if the key is valid
        if [[ -z "$secret_key" || "$secret_key" == "-" ]]; then
            continue
        fi

        expected_reference=$(echo "$secrets" | yq eval ".${secret_key}" -)
        actual_value="${!secret_key}"

        # Verify that the environment variable is set and different from the reference
        if [[ -z "$actual_value" || "$actual_value" == "$expected_reference" ]]; then
            echo "Test failed: $secret_key is not replaced correctly. Got: $actual_value"
            return 1
        else
            echo "Test passed: $secret_key is resolved correctly."
        fi
    done

    echo "Test passed: verify_secrets"
}

# Run the test
if test_verify_secrets; then
    echo "Secrets fetching tests passed successfully."
else
    echo "Secrets fetching tests failed."
    exit 1
fi

# Run the test
if test_verify_secrets; then
    echo "Secrets fetching tests passed successfully."
else
    echo "Secrets fetching tests failed."
    exit 1
fi