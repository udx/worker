#!/bin/sh

echo "Starting validation tests..."

# Print all environment variables for debugging
# echo "Printing all environment variables:"
# env

# Dynamically redact sensitive environment variables for output
# SENSITIVE_PATTERN="PASSWORD|SECRET|KEY|TOKEN"
# env | while IFS='=' read -r name value; do
#     if echo "$name" | grep -Eq "$SENSITIVE_PATTERN"; then
#         echo "$name=********"
#     else
#         echo "$name=$value"
#     fi
# done

# Extract required environment variables from expanded worker.yml
WORKER_CONFIG="/home/$USER/.cd/configs/worker_expanded.yml"
REQUIRED_VARS=$(yq e '.config.env | to_entries | .[].key' "$WORKER_CONFIG")
echo "Required environment variables: $REQUIRED_VARS"

# Ensure all required environment variables are set
for var in $REQUIRED_VARS; do
    if [ -z "$(printenv $var)" ]; then
        echo "Error: Environment variable $var is not set."
        exit 1
    else
        echo "Environment variable $var is set."
    fi
done

# Verify secrets are fetched (assuming secrets are set as environment variables)
SECRETS=$(yq e '.config.workerSecrets | to_entries | .[].key' "$WORKER_CONFIG")
for secret in $SECRETS; do
    if [ -z "$(printenv $secret)" ]; then
        echo "Error: Secret $secret is not resolved correctly."
        exit 1
    else
        echo "Secret $secret is resolved correctly."
    fi
done

# Confirm that actors are unauthenticated (actors' environment variables should not be set)
ACTOR_VARS=$(yq e '.config.workerActors[] | to_entries | .[].value' "$WORKER_CONFIG" | grep -E "PASSWORD|SECRET|KEY|TOKEN")
for var in $ACTOR_VARS; do
    var_name=$(echo $var | sed -e 's/^.*{\(.*\)}.*$/\1/')
    if [ -n "$(printenv $var_name)" ]; then
        echo "Error: Sensitive variable $var_name is still set after cleanup."
        exit 1
    else
        echo "Sensitive variable $var_name is not set that is expected."
    fi
done

echo "All validation tests passed successfully."
