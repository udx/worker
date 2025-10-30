#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# GCP Authentication Module
# Supports: Service Account Keys, Workload Identity Tokens
# All methods use: gcloud auth login --cred-file="$GOOGLE_APPLICATION_CREDENTIALS"
#
# Note: Impersonation is handled externally by setting GOOGLE_APPLICATION_CREDENTIALS
# and CLOUDSDK_AUTH_ACCESS_TOKEN directly, bypassing this module.
#
# Example usage:
#   gcp_authenticate "/path/to/gcp_creds.json"
#   gcp_authenticate "${GCP_CREDS}"

# Function to authenticate with GCP
gcp_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        log_error "GCP Authentication" "No GCP credentials provided."
        return 1
    fi
    
    # If GOOGLE_APPLICATION_CREDENTIALS already set, do not override
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        log_info "GCP Authentication" "GOOGLE_APPLICATION_CREDENTIALS already set, skipping authentication."
        return 0
    fi
    
    local creds_file="$LOCAL_CREDS_DIR/gcp_creds.json"
    
    # Check if this is a service account key that needs private_key normalization
    if echo "$creds_content" | jq -e '.private_key' >/dev/null 2>&1; then
        # Service account key - normalize private_key field
        local clientEmail privateKey projectId
        
        clientEmail=$(echo "$creds_content" | jq -r '.client_email')
        privateKey=$(echo "$creds_content" | jq -r '.private_key')
        projectId=$(echo "$creds_content" | jq -r '.project_id')
        
        # Normalize private_key: handle escaped newlines and spacing issues
        privateKey=$(echo "$privateKey" | sed 's/\\n/\n/g' | sed 's/- /\n-/g' | sed 's/ -/-\n/g')
        
        # Create normalized JSON file
        jq -n --arg clientEmail "$clientEmail" --arg privateKey "$privateKey" --arg projectId "$projectId" \
        '{type: "service_account", client_email: $clientEmail, private_key: $privateKey, project_id: $projectId}' > "$creds_file"
    else
        # Other credential types (workload identity, impersonation) - use as-is
        echo "$creds_content" > "$creds_file"
    fi
    
    # Set GOOGLE_APPLICATION_CREDENTIALS for all methods
    export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
    
    # Set GCP_CREDS for backward compatibility
    export GCP_CREDS="$creds_file"
    
    # Authenticate with gcloud (works for all credential types)
    log_info "GCP Authentication" "Authenticating with gcloud..."
    if ! gcloud auth login --cred-file="$GOOGLE_APPLICATION_CREDENTIALS" >/dev/null 2>&1; then
        log_error "GCP Authentication" "Failed to authenticate with gcloud."
        return 1
    fi
    
    # Extract and set project ID if available
    local projectId
    projectId=$(echo "$creds_content" | jq -r '.project_id // empty' 2>/dev/null)
    
    if [[ -n "$projectId" && "$projectId" != "null" ]]; then
        if ! gcloud config set project "$projectId" >/dev/null 2>&1; then
            log_error "GCP Authentication" "Failed to set GCP project: $projectId"
            return 1
        fi
        log_success "GCP Authentication" "Authenticated successfully. Project: $projectId"
    else
        log_success "GCP Authentication" "Authenticated successfully."
    fi
}