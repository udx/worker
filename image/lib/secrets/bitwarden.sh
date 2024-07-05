#!/bin/sh

# Function to resolve secrets from Bitwarden
resolve_bitwarden_secret() {
    local secret_id=$1
    echo "[INFO] Resolving Bitwarden secret for ID: $secret_id" >&2
    bw get item "$secret_id" | jq -r '.notes' 2>/dev/null
}

# Function to log in to Bitwarden
bitwarden_login() {
    if ! bw login --check; then
        echo "[INFO] Logging in to Bitwarden..."
        BW_SESSION=$(bw login --raw)
        export BW_SESSION
    fi
}
