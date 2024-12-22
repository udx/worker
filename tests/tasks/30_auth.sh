#!/bin/bash

echo "Starting validation of authorization..."

# Path to the merged configuration file
MERGED_CONFIG="/home/${USER}/.cd/configs/merged_worker.yml"

# Function to check if an actor is authorized
check_actor_authorization() {
    local actor_type="$1"
    local creds="$2"
    
    # Resolve the credentials environment variable
    creds=$(eval echo "$creds")

    # Check if the credentials are provided
    if [[ "$creds" == "null" || -z "$creds" ]]; then
        echo "Skipping authorization for $actor_type: No credentials provided."
        return 0
    fi

    # Dummy authorization check (replace with actual logic)
    echo "Authorizing $actor_type with credentials: $creds"
    if [[ "$creds" == *"invalid"* ]]; then
        echo "Authorization failed for $actor_type: Invalid credentials."
        return 1
    fi

    echo "Authorization succeeded for $actor_type."
    return 0
}

# Test authenticate_actors function
test_authenticate_actors() {
    echo "Running test: authenticate_actors"

    # Load the merged configuration
    merged_config=$(cat "$MERGED_CONFIG")

    # Extract actors from the merged configuration
    actors=$(echo "$merged_config" | yq eval -o=json '.config.actors' - | jq -c '.[]')

    # Verify actors and their credentials
    for actor in $actors; do
        _jq() {
            echo "$actor" | jq -r "${1}"
        }

        actor_type=$(_jq '.type')
        creds=$(_jq '.creds')

        echo "Checking actor: $actor_type"
        check_actor_authorization "$actor_type" "$creds"
        if [[ $? -ne 0 ]]; then
            echo "Test failed: Authorization failed for actor $actor_type"
            return 1
        fi
    done

    echo "Test passed: authenticate_actors"
}

# Run the test
if test_authenticate_actors; then
    echo "Authorization tests passed successfully."
else
    echo "Authorization tests failed."
    exit 1
fi