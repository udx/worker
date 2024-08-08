#!/bin/bash

# Function to authenticate with Bitwarden
bitwarden_authenticate() {
    local actor="$1"
    local email
    email=$(echo "$actor" | jq -r '.email')
    local password
    password=$(echo "$actor" | jq -r '.password')
    
    echo "[INFO] Authenticating Bitwarden account..."

    # Check if already logged in
    if ! bw login --check >/dev/null 2>&1; then
        echo "[INFO] Logging in to Bitwarden..."
        if ! bw login --raw "$email" "$password" >/dev/null 2>&1; then
            echo "[ERROR] Bitwarden login failed"
            return 1
        fi
    else
        echo "[INFO] Already logged in to Bitwarden"
    fi
}
