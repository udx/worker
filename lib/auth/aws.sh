#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Example usage of the function
# aws_authenticate "/path/to/your/aws_creds.json"

# Function to authenticate AWS using IAM user credentials
aws_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        log_error "AWS Authentication" "No AWS credentials provided."
        return 1
    fi
    
    # Extract necessary fields from the JSON credentials
    local accessKeyId secretAccessKey sessionToken

    accessKeyId=$(echo "$creds_content" | jq -r '.AccessKeyId')
    secretAccessKey=$(echo "$creds_content" | jq -r '.SecretAccessKey')
    sessionToken=$(echo "$creds_content" | jq -r '.SessionToken')

    if [[ -z "$accessKeyId" || -z "$secretAccessKey" ]]; then
        log_error "AWS Authentication" "Missing required AWS credentials."
        return 1
    fi

    # Export the credentials as environment variables
    export AWS_ACCESS_KEY_ID="$accessKeyId"
    export AWS_SECRET_ACCESS_KEY="$secretAccessKey"
    if [[ -n "$sessionToken" ]]; then
        export AWS_SESSION_TOKEN="$sessionToken"
    fi

    log_success "AWS Authentication" "AWS credentials set successfully."
}