#!/bin/sh

# Source the provider-specific auth modules
source /usr/local/bin/modules/auth/azure.sh
# @TODO: Uncomment the following lines after implementing the auth modules
# source /usr/local/bin/modules/auth/gcp.sh
# source /usr/local/bin/modules/auth/aws.sh

# Function to authenticate actors
authenticate_actors() {
    echo "Authenticating actors"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi

    # Check if the workerActors section exists and is not empty
    if ! yq e '.config.workerActors' "$WORKER_CONFIG" > /dev/null; then
        echo "No workerActors section found in the configuration."
        return 0
    fi

    # Extract actor information and authenticate
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    echo "Extracted actors JSON: $ACTORS_JSON"

    if [ "$ACTORS_JSON" = "null" ]; then
        echo "No actors found in the configuration."
        return 0
    fi

    echo "$ACTORS_JSON" | jq -c '.[]' | while read -r actor; do
        type=$(echo "$actor" | jq -r '.type')
        email=$(echo "$actor" | jq -r '.email')
        password=$(echo "$actor" | jq -r '.password')

        echo "Extracted actor: $actor"
        echo "Extracted actor type: $type"

        if [ -z "$type" ] || [ "$type" == "null" ]; then
            echo "Error: Actor type is null or empty"
            continue
        fi

        # Handle specific actor types
        if [ "$type" = "azure-personal-account" ]; then
            echo "Authenticating Azure personal account: $email"
            az login -u "$email" -p "$password"
        fi

        # Add other actor types handling as needed
        # authenticate_actor "$type" "$actor"
    done
}