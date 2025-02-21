#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Function to resolve Bitwarden secret
resolve_bitwarden_secret() {
    local collection_name="$1"
    local secret_name="$2"
    local secret_value

    if [[ -z "$collection_name" || -z "$secret_name" ]]; then
        log_error "Bitwarden" "Invalid Bitwarden collection name or secret name"
        return 1
    fi

    # Retrieve the secret using Bitwarden CLI
    log_info "Bitwarden" "Retrieving secret from Bitwarden: collection_name=$collection_name, secret_name=$secret_name"
    if ! secret_value=$(bw get item "$secret_name" --organizationid "$collection_name" --output text 2>&1); then
        log_error "Bitwarden" "Failed to retrieve secret from Bitwarden: collection_name=$collection_name, secret_name=$secret_name"
        log_error "Bitwarden" "Bitwarden CLI output: $secret_value"
        return 1
    fi

    if [ -z "$secret_value" ]; then
        log_error "Bitwarden" "Secret value is empty for $secret_name in collection $collection_name"
        return 1
    fi

    printf "%s" "$secret_value"
    return 0
}