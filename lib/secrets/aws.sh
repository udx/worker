#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Function to resolve AWS secret
resolve_aws_secret() {
    local secret_name="$1"
    local region="$2"
    local secret_value

    if [[ -z "$secret_name" || -z "$region" ]]; then
        log_error "AWS" "Invalid AWS secret name or region"
        return 1
    fi

    # Retrieve the secret value using AWS CLI with detailed logging
    log_info "AWS" "Retrieving secret from AWS Secrets Manager: secret_name=$secret_name, region=$region"
    if ! secret_value=$(aws secretsmanager get-secret-value --secret-id "$secret_name" --query 'SecretString' --output text --region "$region" 2>&1); then
        log_error "AWS" "Failed to retrieve secret from AWS Secrets Manager: secret_name=$secret_name, region=$region"
        log_error "AWS" "AWS CLI output: $secret_value"
        return 1
    fi

    if [ -z "$secret_value" ]; then
        log_error "AWS" "Secret value is empty for $secret_name in region $region"
        return 1
    fi

    printf "%s" "$secret_value"
    return 0
}