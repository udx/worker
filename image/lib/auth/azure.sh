#!/bin/sh

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor=$1
    local type=$(echo "$actor" | jq -r '.type')
    local subscription=$(resolve_env_vars "$(echo "$actor" | jq -r '.subscription')")
    local tenant=$(resolve_env_vars "$(echo "$actor" | jq -r '.tenant')")
    local application=$(resolve_env_vars "$(echo "$actor" | jq -r '.application')")
    local password=$(resolve_env_vars "$(echo "$actor" | jq -r '.password')")
    
    case $type in
        "azure-service-principal")
            echo "[INFO] Authenticating Azure service principal: $application"
            az login --service-principal -u "$application" -p "$password" --tenant "$tenant"
            if [ $? -ne 0 ]; then
                echo "[ERROR] Azure service principal authentication failed"
                return 1
            fi
            az account set --subscription "$subscription"
        ;;
        "azure-personal-account")
            echo "[INFO] Authenticating Azure personal account: $application"
            az login -u "$application" -p "$password"
            if [ $? -ne 0 ]; then
                echo "[ERROR] Azure personal account authentication failed"
                return 1
            fi
            if [ -n "$subscription" ]; then
                az account set --subscription "$subscription"
            fi
        ;;
        *)
            echo "[ERROR] Unsupported Azure authentication type $type"
            return 1
        ;;
    esac
}
