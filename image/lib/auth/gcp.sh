#!/bin/sh

# Function to authenticate GCP service account
gcp_authenticate() {
    local actor=$1
    local email=$(echo "$actor" | yq e '.value.email' -)
    local keyfile=$(echo "$actor" | yq e '.value.keyfile' -)

    echo "Authenticating GCP service account: $email"
    echo "$keyfile" > /tmp/gcp_keyfile.json
    gcloud auth activate-service-account "$email" --key-file=/tmp/gcp_keyfile.json
    rm /tmp/gcp_keyfile.json
}
