#!/bin/bash

# Function to resolve Bitwarden secret
resolve_bitwarden_secret() {
    local collection_name="$1"
    local secret_name="$2"
    local secret_value

    if [[ -z "$collection_name" || -z "$secret_name" ]]; then
        echo "[ERROR] Invalid Bitwarden collection name or secret name" >&2
        return 1
    fi

    # Retrieve the secret using Bitwarden CLI
    echo "[INFO] Retrieving secret from Bitwarden: collection_name=$collection_name, secret_name=$secret_name" >&2
    if ! secret_value=$(bw get item "$secret_name" --organizationid "$collection_name" --output text 2>&1); then
        echo "[ERROR] Failed to retrieve secret from Bitwarden: collection_name=$collection_name, secret_name=$secret_name" >&2
        echo "[DEBUG] Bitwarden CLI output: $secret_value" >&2
        return 1
    fi

    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for $secret_name in collection $collection_name" >&2
        return 1
    fi

    printf "%s" "$secret_value"
    return 0
}