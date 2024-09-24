#!/bin/bash

# Function to authenticate GCP service accounts
#
# Example usage of the function
# gcp_authenticate "/path/to/your/gcp_creds.json"
#

# Function to authenticate GCP service accounts
gcp_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        echo "[ERROR] No GCP credentials provided." >&2
        return 1
    fi
    
    # Extract necessary fields from the JSON credentials
    local clientEmail privateKey projectId
    
    clientEmail=$(echo "$creds_content" | jq -r '.client_email')
    privateKey=$(echo "$creds_content" | jq -r '.private_key')
    projectId=$(echo "$creds_content" | jq -r '.project_id')
    
    if [[ -z "$clientEmail" || -z "$privateKey" || -z "$projectId" ]]; then
        echo "[ERROR] Missing required GCP credentials." >&2
        return 1
    fi
    
    # Create a temporary credentials file for gcloud authentication
    local temp_creds_file="/tmp/gcp_creds.json"
    echo "$creds_content" > "$temp_creds_file"
    
    echo "[INFO] Authenticating GCP service account..."
    if ! gcloud auth activate-service-account "$clientEmail" --key-file="$temp_creds_file" >/dev/null 2>&1; then
        echo "[ERROR] GCP service account authentication failed." >&2
        rm -f "$temp_creds_file"
        return 1
    fi
    
    if ! gcloud config set project "$projectId" >/dev/null 2>&1; then
        echo "[ERROR] Failed to set GCP project." >&2
        rm -f "$temp_creds_file"
        return 1
    fi
    
    echo "[INFO] GCP service account authenticated and project set."
    
    # Clean up temporary credentials file
    rm -f "$temp_creds_file"
}