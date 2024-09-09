#!/bin/bash

# Example usage of the function
# aws_authenticate "/path/to/your/aws_creds.json"
#
# Example AWS credentials JSON file:
#
# {
#     "AccessKeyId": "your-access-key-id",
#     "SecretAccessKey": "your-secret-access-key",
#     "Region": "your-aws-region"
# }

# Function to authenticate AWS using IAM user credentials
aws_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        echo "[ERROR] No AWS credentials provided." >&2
        return 1
    fi
    
    # Extract necessary fields from the JSON credentials
    local accessKeyId secretAccessKey region
    
    accessKeyId=$(echo "$creds_content" | jq -r '.AccessKeyId')
    secretAccessKey=$(echo "$creds_content" | jq -r '.SecretAccessKey')
    region=$(echo "$creds_content" | jq -r '.Region')
    
    if [[ -z "$accessKeyId" || -z "$secretAccessKey" || -z "$region" ]]; then
        echo "[ERROR] Missing required AWS credentials." >&2
        return 1
    fi
    
    # Set AWS credentials as environment variables
    export AWS_ACCESS_KEY_ID="$accessKeyId"
    export AWS_SECRET_ACCESS_KEY="$secretAccessKey"
    export AWS_DEFAULT_REGION="$region"
    
    # Test authentication by listing S3 buckets or another simple AWS service operation
    echo "[INFO] Testing AWS authentication..."
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "[ERROR] AWS authentication failed." >&2
        return 1
    fi
    
    echo "[INFO] AWS authenticated successfully."
}

# Example usage of the function
# aws_authenticate "/path/to/your/aws_creds.json"
