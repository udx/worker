#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

log_info "Starting validation of config..."

# Path to the merged configuration file
MERGED_CONFIG="/usr/local/configs/worker/merged_worker.yaml"

# Test configure_environment function
test_configure_environment() {
    log_info "Running test: configure_environment"

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
            log_error "Config" "$key is not set correctly. Expected: $value, Got: $actual_value"
            return 1
        else
            log_success "Config" "$key is set correctly"
        fi
    done

    log_success "Config" "configure_environment test passed"
    return 0
}

# Run the test
if test_configure_environment; then
    log_success "Config" "All config tests passed successfully"
else
    log_error "Config" "Config tests failed"
    exit 1
fi