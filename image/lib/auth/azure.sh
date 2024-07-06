#!/bin/sh

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor=$1
    local type=$(echo "$actor" | jq -r '.type')
    local subscription=$(resolve_env_vars "$(echo "$actor" | jq -r '.subscription')")
    local tenant=$(resolve_env_vars "$(echo "$actor" | jq -r '.tenant')")
    local application=$(resolve_env_vars "$(echo "$actor" | jq -r '.application')")
    local password=$(resolve_env_vars "$(echo "$actor" | jq -r '.password')")
    local email=$(resolve_env_vars "$(echo "$actor" | jq -r '.email')")

    echo "[DEBUG] Authenticating Azure account with type: $type"

    case $type in
        "azure-service-principal")
            echo "[INFO] Authenticating Azure service principal: $application"
            az login --service-principal -u "$application" -p "$password" --tenant "$tenant" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "[ERROR] Azure service principal authentication failed"
                return 1
            fi
            az account set --subscription "$subscription" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "[ERROR] Failed to set Azure subscription: $subscription"
                return 1
            fi
            ;;
        "azure-personal-account")
            echo "[INFO] Authenticating Azure personal account: $email"
            az login -u "$email" -p "$password" >/dev/null 2>&1
            if [ $? -ne 0 ]; then
                echo "[ERROR] Azure personal account authentication failed"
                return 1
            fi
            if [ -n "$subscription" ]; then
                az account set --subscription "$subscription" >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    echo "[ERROR] Failed to set Azure subscription: $subscription"
                    return 1
                fi
            fi
            ;;
        *)
            echo "[ERROR] Unsupported Azure authentication type: $type"
            return 1
            ;;
    esac

    echo "[INFO] Azure authentication successful for type: $type"
    return 0
}
