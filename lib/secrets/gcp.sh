#!/bin/bash

# Function to resolve GCP secret
resolve_gcp_secret() {
    local project_id="$1"
    local secret_name="$2"
    local secret_value

    # Validate input arguments
    if [[ -z "$project_id" || -z "$secret_name" ]]; then
        log_error "Invalid GCP project ID or secret name. project_id: $project_id, secret_name: $secret_name"
        return 1
    fi

    # log_info "Retrieving secret from GCP Secret Manager: project_id=$project_id, secret_name=$secret_name"

    # Retrieve the latest version of the secret
    if ! secret_value=$(gcloud secrets versions access latest --secret="$secret_name" --project="$project_id" 2>/tmp/gcp_secret_error.log); then
        log_error "Failed to retrieve secret from GCP Secret Manager for secret: $secret_name"
        log_error "GCP CLI output: $(cat /tmp/gcp_secret_error.log)"
        return 1
    fi

    # Check if the secret value is empty
    if [[ -z "$secret_value" ]]; then
        log_error "Secret value is empty for secret: $secret_name in project: $project_id"
        return 1
    fi

    # Output only the secret value
    printf "%s" "$secret_value"
    return 0
}
