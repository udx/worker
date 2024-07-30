#!/bin/sh

# Function to authenticate GCP service account
gcp_authenticate() {
    local actor=$1
    local email=$(echo "$actor" | jq -r '.email')
    local keyfile=$(resolve_env_vars "$(echo "$actor" | jq -r '.keyfile')")

    echo "[INFO] Authenticating GCP service account: $email"
    
    # Write the keyfile content to a temporary file
    echo "$keyfile" > /tmp/gcp_keyfile.json
    
    # Authenticate using the keyfile
    gcloud auth activate-service-account "$email" --key-file=/tmp/gcp_keyfile.json >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "[ERROR] GCP service account authentication failed"
        rm /tmp/gcp_keyfile.json
        return 1
    fi
    
    # Clean up the temporary keyfile
    rm /tmp/gcp_keyfile.json
}
