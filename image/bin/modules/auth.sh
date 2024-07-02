#!/bin/sh

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

    # Extract actor information and authenticate
    yq e '.config.workerActors | to_entries | .[]' "$WORKER_CONFIG" | while read -r actor; do
        type=$(echo "$actor" | yq e '.value.type' -)
        subscription=$(echo "$actor" | yq e '.value.subscription' -)
        tenant=$(echo "$actor" | yq e '.value.tenant' -)
        application=$(echo "$actor" | yq e '.value.application' -)
        password=$(echo "$actor" | yq e '.value.password' -)
        email=$(echo "$actor" | yq e '.value.email' -)
        keyfile=$(echo "$actor" | yq e '.value.keyfile' -)
        
        echo "Authenticating actor of type: $type"
        
        # Perform authentication logic for Azure
        if [ "$type" == "azure-service-principal" ]; then
            az login --service-principal -u "$application" -p "$password" --tenant "$tenant"
            az account set --subscription "$subscription"
        fi
        
        # Perform authentication logic for GCP
        if [ "$type" == "gcp-service-account" ]; then
            echo "$keyfile" > /tmp/gcp_keyfile.json
            gcloud auth activate-service-account "$email" --key-file=/tmp/gcp_keyfile.json
            rm /tmp/gcp_keyfile.json
        fi
    done
}
