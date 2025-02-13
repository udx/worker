#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Function to resolve Azure secret
resolve_azure_secret() {
    local key_vault_name="$1"
    local secret_name="$2"
    local secret_value
    
    if [ -z "$key_vault_name" ] || [ -z "$secret_name" ]; then
        log_error "Azure" "Invalid Azure Key Vault name or secret name"
        return 1
    fi
    
    # Retrieve the secret value using Azure CLI with detailed logging
    log_info "Azure" "Retrieving secret from Azure Key Vault: vault_name=$key_vault_name, secret_name=$secret_name"
    if ! secret_value=$(az keyvault secret show --vault-name "$key_vault_name" --name "$secret_name" --query value -o tsv 2>&1); then
        log_error "Azure" "Failed to retrieve secret from Azure Key Vault: vault_name=$key_vault_name, secret_name=$secret_name"
        log_error "Azure" "Azure CLI output: $secret_value"
        return 1
    fi
    
    if [ -z "$secret_value" ]; then
        log_error "Azure" "Secret value is empty for $key_vault_name/$secret_name"
        return 1
    fi
    
    printf "%s" "$secret_value"
    return 0
}
