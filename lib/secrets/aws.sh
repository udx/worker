#!/bin/bash

# Function to resolve AWS secret
resolve_aws_secret() {
    local secret_name="$1"
    local region="$2"
    local secret_value

    if [[ -z "$secret_name" || -z "$region" ]]; then
        echo "[ERROR] Invalid AWS secret name or region" >&2
        return 1
    fi

    # Retrieve the secret value using AWS CLI with detailed logging
    echo "[INFO] Retrieving secret from AWS Secrets Manager: secret_name=$secret_name, region=$region" >&2
    if ! secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_name" --query 'SecretString' --output text --region "$region" 2>&1); then
        echo "[ERROR] Failed to retrieve secret from AWS Secrets Manager: secret_name=$secret_name, region=$region" >&2
        echo "[DEBUG] AWS CLI output: $secret_value" >&2
        return 1
    fi

    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for $secret_name in region $region" >&2
        return 1
    fi

    printf "%s" "$secret_value"
    return 0
}