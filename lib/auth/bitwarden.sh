#!/bin/bash

# Function to authenticate Bitwarden using API key or master password
#
# Example usage of the function
# bitwarden_authenticate "/path/to/your/bitwarden_creds.json"
#
# Example Bitwarden credentials JSON file:
#
# {
#     "clientId": "your-client-id",
#     "clientSecret": "your-client-secret",
#     "masterPassword": "your-master-password"
# }
#

# Function to authenticate Bitwarden using API key or master password
bitwarden_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        echo "[ERROR] No Bitwarden credentials provided." >&2
        return 1
    fi
    
    # Extract necessary fields from the JSON credentials
    local clientId clientSecret masterPassword
    
    clientId=$(echo "$creds_content" | jq -r '.clientId')
    clientSecret=$(echo "$creds_content" | jq -r '.clientSecret')
    masterPassword=$(echo "$creds_content" | jq -r '.masterPassword')
    
    if [[ -z "$clientId" || -z "$clientSecret" || -z "$masterPassword" ]]; then
        echo "[ERROR] Missing required Bitwarden credentials." >&2
        return 1
    fi
    
    # Log in to Bitwarden CLI using API key
    echo "[INFO] Authenticating Bitwarden using client ID and secret..."
    if ! bw login --apikey --client-id "$clientId" --client-secret "$clientSecret" >/dev/null 2>&1; then
        echo "[ERROR] Bitwarden login failed." >&2
        return 1
    fi
    
    # Unlock the vault using the master password
    echo "[INFO] Unlocking the Bitwarden vault..."
    if ! bw unlock "$masterPassword" --raw >/dev/null 2>&1; then
        echo "[ERROR] Failed to unlock the Bitwarden vault." >&2
        return 1
    fi
    
    echo "[INFO] Bitwarden authenticated and vault unlocked successfully."
}

# Example usage of the function
# bitwarden_authenticate "/path/to/your/bitwarden_creds.json"
