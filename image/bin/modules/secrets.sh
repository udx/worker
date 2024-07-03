#!/bin/sh

# Function to fetch secrets
fetch_secrets() {
    echo "Fetching secrets"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Check if workerSecrets is defined
    if ! yq e '.config.workerSecrets' "$WORKER_CONFIG" >/dev/null; then
        echo "No workerSecrets configuration found"
        return 0
    fi

    # Use yq to extract secrets and set them as environment variables
    yq e '.config.workerSecrets | to_entries | .[] | "export " + .key + "=" + "\"" + .value + "\""' "$WORKER_CONFIG" > /tmp/secrets.sh
    
    # Source the generated script to set secrets as environment variables
    if [ -f /tmp/secrets.sh ]; then
        . /tmp/secrets.sh
    else
        echo "Error: Generated secrets script not found"
        return 1
    fi

    echo "Secrets fetched and set as environment variables"
}
