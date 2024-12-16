#!/bin/bash

# Example usage of the function
# aws_authenticate "/path/to/your/aws_creds.json"

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
    local accessKeyId secretAccessKey sessionToken

    accessKeyId=$(echo "$creds_content" | jq -r '.AccessKeyId')
    secretAccessKey=$(echo "$creds_content" | jq -r '.SecretAccessKey')
    sessionToken=$(echo "$creds_content" | jq -r '.SessionToken')

    if [[ -z "$accessKeyId" || -z "$secretAccessKey" ]]; then
        echo "[ERROR] Missing required AWS credentials." >&2
        return 1
    fi

    # Export the credentials as environment variables
    export AWS_ACCESS_KEY_ID="$accessKeyId"
    export AWS_SECRET_ACCESS_KEY="$secretAccessKey"
    if [[ -n "$sessionToken" ]]; then
        export AWS_SESSION_TOKEN="$sessionToken"
    fi

    echo "[INFO] AWS credentials set successfully."
}