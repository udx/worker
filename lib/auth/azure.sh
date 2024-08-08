#!/bin/bash

# Function to resolve environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor="$1"
    local type
    type=$(echo "$actor" | jq -r '.type')
    local subscription
    subscription=$(resolve_env_vars "$(echo "$actor" | jq -r '.subscription')")
    local tenant
    tenant=$(resolve_env_vars "$(echo "$actor" | jq -r '.tenant')")
    local application
    application=$(resolve_env_vars "$(echo "$actor" | jq -r '.application')")
    local password
    password=$(resolve_env_vars "$(echo "$actor" | jq -r '.password')")
    
    case $type in
        "azure-service-principal")
            echo "[INFO] Authenticating Azure service principal: $application"
            if ! az login --service-principal -u "$application" -p "$password" --tenant "$tenant" >/dev/null 2>&1; then
                echo "[ERROR] Azure service principal authentication failed"
                return 1
            fi
            if ! az account set --subscription "$subscription" >/dev/null 2>&1; then
                echo "[ERROR] Failed to set Azure subscription"
                return 1
            fi
        ;;
        "azure-personal-account")
            echo "[INFO] Authenticating Azure personal account: $application"
            if ! az login -u "$application" -p "$password" >/dev/null 2>&1; then
                echo "[ERROR] Azure personal account authentication failed"
                return 1
            fi
            if [ -n "$subscription" ]; then
                if ! az account set --subscription "$subscription" >/dev/null 2>&1; then
                    echo "[ERROR] Failed to set Azure subscription"
                    return 1
                fi
            fi
        ;;
        *)
            echo "[ERROR] Unsupported Azure authentication type $type"
            return 1
        ;;
    esac
}
