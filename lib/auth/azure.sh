#!/bin/bash

# Function to authenticate Azure accounts
azure_authenticate() {
    local creds_json="$1"

    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")

    if [[ -z "$creds_content" ]]; then
        echo "[ERROR] No Azure credentials provided." >&2
        return 1
    fi

    # Extract necessary fields from the JSON credentials
    local clientId clientSecret subscriptionId tenantId

    clientId=$(echo "$creds_content" | jq -r '.clientId')
    clientSecret=$(echo "$creds_content" | jq -r '.clientSecret')
    subscriptionId=$(echo "$creds_content" | jq -r '.subscriptionId')
    tenantId=$(echo "$creds_content" | jq -r '.tenantId')

    if [[ -z "$clientId" || -z "$clientSecret" || -z "$subscriptionId" || -z "$tenantId" ]]; then
        echo "[ERROR] Missing required Azure credentials." >&2
        return 1
    fi

    echo "[INFO] Authenticating Azure service principal..."
    if ! az login --service-principal -u "$clientId" -p "$clientSecret" --tenant "$tenantId" >/dev/null 2>&1; then
        echo "[ERROR] Azure service principal authentication failed." >&2
        return 1
    fi

    if ! az account set --subscription "$subscriptionId" >/dev/null 2>&1; then
        echo "[ERROR] Failed to set Azure subscription." >&2
        return 1
    fi

    echo "[INFO] Azure service principal authenticated and subscription set."
}
