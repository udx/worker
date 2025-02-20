#!/bin/bash

# Function to authenticate Azure accounts
#
# Example usage of the function
# azure_authenticate "/path/to/your/azure_creds.json"

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Function to authenticate Azure accounts
azure_authenticate() {
    local creds_json="$1"

    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")

    if [[ -z "$creds_content" ]]; then
        log_error "Azure Authentication" "No Azure credentials provided."
        return 1
    fi

    # Extract necessary fields from the JSON credentials
    local clientId clientSecret subscriptionId tenantId

    clientId=$(echo "$creds_content" | jq -r '.clientId')
    clientSecret=$(echo "$creds_content" | jq -r '.clientSecret')
    subscriptionId=$(echo "$creds_content" | jq -r '.subscriptionId')
    tenantId=$(echo "$creds_content" | jq -r '.tenantId')

    if [[ -z "$clientId" || -z "$clientSecret" || -z "$subscriptionId" || -z "$tenantId" ]]; then
        log_error "Azure Authentication" "Missing required Azure credentials."
        return 1
    fi

    log_info "Authenticating Azure service principal..."
    if ! az login --service-principal -u "$clientId" -p "$clientSecret" --tenant "$tenantId" >/dev/null 2>&1; then
        log_error "Azure Authentication" "Azure service principal authentication failed."
        return 1
    fi

    if ! az account set --subscription "$subscriptionId" >/dev/null 2>&1; then
        log_error "Azure Authentication" "Failed to set Azure subscription."
        return 1
    fi

    log_success "Azure Authentication" "Azure service principal authenticated and subscription set."
}
