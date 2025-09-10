#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Function to authenticate GCP service accounts
#
# Example usage of the function
# gcp_authenticate "/path/to/your/gcp_creds.json"
#

# Function to authenticate GCP service accounts
gcp_authenticate() {
    local creds_json="$1"
    
    # Read the contents of the file
    local creds_content
    creds_content=$(cat "$creds_json")
    
    if [[ -z "$creds_content" ]]; then
        log_error "GCP Authentication" "No GCP credentials provided."
        return 1
    fi
    
    # Extract necessary fields from the JSON credentials
    local clientEmail privateKey projectId
    
    clientEmail=$(echo "$creds_content" | jq -r '.client_email')
    privateKey=$(echo "$creds_content" | jq -r '.private_key' | sed 's/- /-\n/g' | sed 's/ -/\n-/g')
    projectId=$(echo "$creds_content" | jq -r '.project_id')
    
    if [[ -z "$clientEmail" || -z "$privateKey" || -z "$projectId" ]]; then
        log_error "GCP Authentication" "Missing required GCP credentials."
        return 1
    fi
    
    # Adjust privateKey formatting
    # Replace "\\n" with actual new line, handle BEGIN and END markers
    privateKey=$(echo "$privateKey" | sed 's/\\n/\n/g' | sed 's/- /\n-/g' | sed 's/ -/-\n/g')
    
    # Create a temporary credentials file for gcloud authentication
    local temp_creds_file="/tmp/gcp_creds.json"
    # Use jq to create a valid JSON with the modified privateKey
    jq -n --arg clientEmail "$clientEmail" --arg privateKey "$privateKey" --arg projectId "$projectId" \
    '{client_email: $clientEmail, private_key: $privateKey, project_id: $projectId}' > "$temp_creds_file"

    # Set GOOGLE_APPLICATION_CREDENTIALS if ACTORS_CLEANUP is false
    if [ "$ACTORS_CLEANUP" = false ]; then
        mkdir -p "$HOME/creds"
        cat "$creds_json" > "$HOME/creds/gcp_creds.json"
        export GOOGLE_APPLICATION_CREDENTIALS="$HOME/creds/gcp_creds.json"
    fi
    
    log_info "GCP Authentication" "Authenticating GCP service account..."
    if ! gcloud auth activate-service-account "$clientEmail" --key-file="$temp_creds_file" >/dev/null 2>&1; then
        log_error "GCP Authentication" "GCP service account authentication failed."
        rm -f "$temp_creds_file"
        return 1
    fi
    
    if ! gcloud config set project "$projectId" >/dev/null 2>&1; then
        log_error "GCP Authentication" "Failed to set GCP project."
        rm -f "$temp_creds_file"
        return 1
    fi
    
    log_success "GCP Authentication" "GCP service account authenticated and project set."
    
    # Clean up temporary credentials file
    rm -f "$temp_creds_file"
}