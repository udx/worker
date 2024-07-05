#!/bin/sh

# Function to resolve secrets from Azure Key Vault
resolve_azure_secret() {
    local secret_url=$1
    echo "Resolving Azure secret for URL: $secret_url" >&2
    az keyvault secret show --id "$secret_url" --query "value" -o tsv 2>/dev/null
}
