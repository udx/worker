#!/bin/sh

# Function to cleanup Azure authentication
cleanup_azure() {
    echo "Cleaning up Azure authentication"
    az logout
}

# Function to cleanup GCP authentication
cleanup_gcp() {
    echo "Cleaning up GCP authentication"
    gcloud auth revoke --all
}

# Function to cleanup AWS authentication
cleanup_aws() {
    echo "Cleaning up AWS authentication"
    # Example: If using AWS CLI v2, this is a placeholder for AWS logout
    # aws sso logout
}

# Function to cleanup actors
cleanup_actors() {
    echo "Cleaning up actors"
    
    # Check the type of each actor and clean up accordingly
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    echo "Extracted actors JSON: $(redact_password "$ACTORS_JSON")"

    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while read -r actor; do
        type=$(echo "$actor" | jq -r '.value.type')
        
        case $type in
            azure-service-principal)
                cleanup_azure
                ;;
            gcp-service-account)
                cleanup_gcp
                ;;
            aws-sso)
                cleanup_aws
                ;;
            *)
                echo "Unsupported actor type for cleanup: $type"
                ;;
        esac
    done
}

# Initialize the cleanup module
init_cleanup() {
    echo "Initializing cleanup module"
}
