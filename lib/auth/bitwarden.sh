#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Function to authenticate Bitwarden using API key or master password
#
# Example usage of the function
# bitwarden_authenticate "/path/to/your/bitwarden_creds.json"

bitwarden_authenticate() {
    local creds_file="$1"

    if [[ ! -f "$creds_file" ]]; then
        log_error "Bitwarden Authentication" "Credentials file not found: $creds_file"
        return 1
    fi

    # Read the credentials file
    local creds_content
    creds_content=$(cat "$creds_file")

    if [[ -z "$creds_content" ]]; then
        log_error "Bitwarden Authentication" "Credentials file is empty: $creds_file"
        return 1
    fi

    # Extract API key or master password
    local api_key master_password
    api_key=$(echo "$creds_content" | jq -r '.apiKey // empty')
    master_password=$(echo "$creds_content" | jq -r '.masterPassword // empty')
    
    if [[ -z "$api_key" && -z "$master_password" ]]; then
        log_error "Bitwarden Authentication" "Either API key or master password must be provided in the credentials file."
        return 1
    fi

    # Authenticate with Bitwarden and get the session key
    local session_key
    if [[ -n "$api_key" ]]; then
        session_key=$(bw login --apikey "$api_key" --raw 2>/dev/null)
    elif [[ -n "$master_password" ]]; then
        local email
        email=$(echo "$creds_content" | jq -r '.email // empty')
        if [[ -z "$email" ]]; then
            log_error "Bitwarden Authentication" "Email must be provided with the master password."
            return 1
        fi
        session_key=$(bw login "$email" "$master_password" --raw 2>/dev/null)
    fi

    if [[ -z "$session_key" ]]; then
        log_error "Bitwarden Authentication" "Failed to authenticate with Bitwarden."
        return 1
    fi
    
    log_success "Bitwarden Authentication" "Authenticated with Bitwarden."
    export BW_SESSION="$session_key"
    return 0
}