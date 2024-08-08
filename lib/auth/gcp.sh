#!/bin/bash

# Function to resolve environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to authenticate GCP service account
gcp_authenticate() {
    local actor="$1"
    local email
    email=$(echo "$actor" | jq -r '.email')
    local keyfile
    keyfile=$(resolve_env_vars "$(echo "$actor" | jq -r '.keyfile')")

    echo "[INFO] Authenticating GCP service account: $email"
    
    # Write the keyfile content to a temporary file
    echo "$keyfile" > /tmp/gcp_keyfile.json
    
    # Authenticate using the keyfile
    if ! gcloud auth activate-service-account "$email" --key-file=/tmp/gcp_keyfile.json >/dev/null 2>&1; then
        echo "[ERROR] GCP service account authentication failed"
        rm /tmp/gcp_keyfile.json
        return 1
    fi
    
    # Clean up the temporary keyfile
    rm /tmp/gcp_keyfile.json
}

# Example usage
# gcp_authenticate '{"email": "example@example.com", "keyfile": "your-key-file-content"}'
