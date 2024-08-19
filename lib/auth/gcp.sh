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

    # Authenticate using the keyfile directly, if possible
    # Check if gcloud can accept keyfile content directly, otherwise use a secure method
    if ! gcloud auth activate-service-account "$email" --key-file=<(echo "$keyfile") >/dev/null 2>&1; then
        echo "[ERROR] GCP service account authentication failed"
        return 1
    fi
}

# Example usage
# gcp_authenticate '{"email": "example@example.com", "keyfile": "your-key-file-content"}'
