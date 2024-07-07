#!/bin/sh

echo "Starting tests..."

# Load the worker configuration
WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
if [ ! -f "$WORKER_CONFIG" ]; then
    echo "Error: Configuration file not found at $WORKER_CONFIG"
    exit 1
fi

# Print all environment variables for debugging
echo "Printing all environment variables:"

# Dynamically redact sensitive environment variables
SENSITIVE_PATTERN="PASSWORD|SECRET|KEY|TOKEN"
env | while IFS='=' read -r name value; do
    if echo "$name" | grep -Eq "$SENSITIVE_PATTERN"; then
        echo "$name=********"
    else
        echo "$name=$value"
    fi
done

# Read environment variables from worker.yml
env_vars=$(yq e '.config.env' "$WORKER_CONFIG" | jq -r 'to_entries | map("\(.key)=\(.value)") | .[]')

# Test environment variables
for env_var in $env_vars; do
    var_name=$(echo $env_var | cut -d '=' -f 1)
    expected_value=$(echo $env_var | cut -d '=' -f 2-)
    actual_value=$(printenv $var_name)

    if [ -z "$actual_value" ]; then
        echo "Error: $var_name environment variable is not set"
        exit 1
    elif [ "$actual_value" != "$expected_value" ]; then
        echo "Error: $var_name environment variable is not set correctly"
        exit 1
    fi
done

# Read secrets from worker.yml
secrets=$(yq e '.config.workerSecrets' "$WORKER_CONFIG" | jq -r 'to_entries | map("\(.key)") | .[]')

# Test secret resolution (assuming secrets are set as environment variables)
for secret in $secrets; do
    if [ -z "$(printenv $secret)" ]; then
        echo "Error: Secret $secret is not resolved correctly"
        exit 1
    fi
done

# Extract sensitive variables from workerActors
actor_vars=$(yq e '.config.workerActors[]' "$WORKER_CONFIG" | jq -r 'to_entries | map("\(.value | tostring)") | .[]' | grep -Ei "$SENSITIVE_PATTERN")

# Ensure sensitive variables used in workerActors are not set after cleanup, only if they are not defined in worker.yml -> env
for var in $actor_vars; do
    var_name=$(echo $var | sed -e 's/^.*{\(.*\)}.*$/\1/')
    if ! echo "$env_vars" | grep -q "$var_name"; then
        if [ -n "$(printenv $var_name)" ]; then
            echo "Error: Sensitive variable $var_name is still set after cleanup"
            exit 1
        fi
    fi
done

echo "All tests passed successfully."
