#!/bin/bash

# Function to resolve Azure secret
resolve_azure_secret() {
    local key_vault_name="$1"
    local secret_name="$2"
    local secret_value
    
    if [ -z "$key_vault_name" ] || [ -z "$secret_name" ]; then
        echo "[ERROR] Invalid Azure Key Vault name or secret name" >&2
        return 1
    fi
    
    # Retrieve the secret value using Azure CLI with detailed logging
    echo "[INFO] Retrieving secret from Azure Key Vault: vault_name=$key_vault_name, secret_name=$secret_name" >&2
    secret_value=$(az keyvault secret show --vault-name "$key_vault_name" --name "$secret_name" --query value -o tsv 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to retrieve secret from Azure Key Vault: vault_name=$key_vault_name, secret_name=$secret_name" >&2
        echo "[DEBUG] Azure CLI output: $secret_value" >&2
        return 1
    fi
    
    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for $key_vault_name/$secret_name" >&2
        return 1
    fi
    
    printf "%s" "$secret_value"
    return 0
}
