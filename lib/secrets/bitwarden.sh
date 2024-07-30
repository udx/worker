#!/bin/sh

# Function to resolve secrets from Bitwarden
resolve_bitwarden_secret() {
    local secret_id=$1

    echo "[INFO] Resolving Bitwarden secret for ID: $secret_id" >&2
    secret_value=$(bw get item "$secret_id" | jq -r '.notes' 2>&1)

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to retrieve Bitwarden secret for ID: $secret_id" >&2
        return 1
    fi

    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for Bitwarden ID: $secret_id" >&2
        return 1
    fi

    echo "$secret_value"
    return 0
}
