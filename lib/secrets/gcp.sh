#!/bin/bash

# Function to resolve secrets from GCP Secret Manager
resolve_gcp_secret() {
    local secret_url="$1"
    local project_id
    local secret_name
    local secret_value
    
    # Extract project ID and secret name from the URL
    project_id=$(echo "$secret_url" | sed -n 's|https://secretmanager.googleapis.com/v1/projects/\([^/]*\)/secrets/\([^/]*\)/.*|\1|p')
    secret_name=$(echo "$secret_url" | sed -n 's|https://secretmanager.googleapis.com/v1/projects/[^/]*/secrets/\([^/]*\)/.*|\1|p')
    
    if [ -z "$project_id" ] || [ -z "$secret_name" ]; then
        echo "[ERROR] Invalid GCP Secret Manager URL: $secret_url"
        return 1
    fi
    
    echo "[INFO] Resolving GCP secret for project: $project_id, secret: $secret_name" >&2
    secret_value=$(gcloud secrets versions access latest --secret="$secret_name" --project="$project_id" 2>&1)
    
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to retrieve GCP secret for URL: $secret_url" >&2
        return 1
    fi
    
    if [ -z "$secret_value" ]; then
        echo "[ERROR] Secret value is empty for GCP URL: $secret_url" >&2
        return 1
    fi
    
    echo "$secret_value"
    return 0
}
