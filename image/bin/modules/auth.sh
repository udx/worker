#!/bin/sh

# Source the provider-specific auth modules
source /usr/local/bin/modules/auth/azure.sh
# @TODO: Uncomment the following lines after implementing the auth modules
# @TODO: and setting up the environment with the necessary CLI tools
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
    
    # Check if workerActors is defined
    if ! yq e '.config.workerActors' "$WORKER_CONFIG" >/dev/null; then
        echo "No workerActors configuration found"
        return 0
    fi

    # Extract actor information and authenticate
    yq e '.config.workerActors | to_entries | .[]' "$WORKER_CONFIG" | while read -r actor; do
        type=$(echo "$actor" | yq e '.value.type' -)
        authenticate_actor "$type" "$actor"
    done
}

# Function to call the appropriate authentication function based on the actor type
authenticate_actor() {
    local type=$1
    local actor=$2

    case $type in
        "azure-service-principal"|"azure-personal-account")
            azure_authenticate "$actor"
            ;;
        "gcp-service-account")
            gcp_authenticate "$actor"
            ;;
        "aws-role")
            aws_authenticate "$actor"
            ;;
        *)
            echo "Error: Unsupported actor type $type"
            ;;
    esac
}
