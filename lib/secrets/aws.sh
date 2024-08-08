#!/bin/bash

# Function to resolve AWS secret
resolve_aws_secret() {
    local secret_arn="$1"
    local region="$2"
    local secret_value

    if [ -z "$region" ]; then
        region="us-east-1"  # Default region if not specified
    fi

    echo "[INFO] Resolving AWS secret for ARN: $secret_arn in region: $region" >&2
    secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" --region "$region" --query SecretString --output text 2>&1)

    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to retrieve AWS secret for ARN: $secret_arn" >&2
        return 1
    fi

    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for AWS ARN: $secret_arn" >&2
        return 1
    fi

    echo "$secret_value"
    return 0
}
