#!/bin/sh

# Function to authenticate with Bitwarden
bitwarden_authenticate() {
    local actor=$1
    local email=$(echo "$actor" | jq -r '.email')
    local password=$(echo "$actor" | jq -r '.password')
    
    echo "Authenticating Bitwarden account..."
    if ! bw login --check; then
        echo "Logging in to Bitwarden..."
        bw login "$email" "$password"
    fi
}
