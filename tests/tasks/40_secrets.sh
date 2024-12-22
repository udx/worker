#!/bin/bash

echo "Starting validation of secrets fetching..."

# Path to the merged configuration file
MERGED_CONFIG="/home/${USER}/.cd/configs/merged_worker.yml"

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
        expected_value=$(echo "$secrets" | yq eval ".${secret_key}" -)

        # Verify that the environment variable is set correctly
        if [[ "${!secret_key}" != "$expected_value" ]]; then
            echo "Test failed: $secret_key is not set correctly. Expected: $expected_value, Got: ${!secret_key}"
            return 1
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