#!/bin/bash

echo "Starting validation tests..."

# Dynamically redact sensitive environment variables for output
redact_sensitive_vars() {
    local var_name="$1"
    local value="$2"
    local SENSITIVE_PATTERN="PASSWORD|SECRET|KEY|TOKEN"
    if echo "$var_name" | grep -Eq "$SENSITIVE_PATTERN"; then
        echo "$var_name=********"
    else
        echo "$var_name=$value"
    fi
}

# Extract required environment variables from the configuration
WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
REQUIRED_VARS=$(yq e '.config.env | to_entries | .[].key' "$WORKER_CONFIG")
echo "Required environment variables: $REQUIRED_VARS"

# Ensure all required environment variables are set
for var in $REQUIRED_VARS; do
    value=$(printenv "$var")
    if [ -z "$value" ]; then
        echo "Error: Environment variable $var is not set."
        exit 1
    else
        echo "Environment variable $var is set."
    fi
done

# Verify secrets are fetched (assuming secrets are set as environment variables)
SECRETS=$(yq e '.config.workerSecrets | to_entries | .[].key' "$WORKER_CONFIG")
for secret in $SECRETS; do
    value=$(printenv "$secret")
    if [ -z "$value" ]; then
        echo "Error: Secret $secret is not resolved correctly."
        exit 1
    else
        echo "Secret $secret is resolved correctly."
    fi
done

# Confirm that sensitive actor variables are not set
ACTOR_VARS=$(yq e '.config.workerActors[] | to_entries | .[].value' "$WORKER_CONFIG" | grep -E "PASSWORD|SECRET|KEY|TOKEN")
for var in $ACTOR_VARS; do
    var_name=$(echo "$var" | sed -e 's/^.*{\(.*\)}.*$/\1/')
    if [ -n "$(printenv "$var_name")" ]; then
        echo "Error: Sensitive variable $var_name is still set after cleanup."
        exit 1
    else
        echo "Sensitive variable $var_name is not set as expected."
    fi
done

echo "All validation tests passed successfully."
