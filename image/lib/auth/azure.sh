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

    case $type in
        "azure-service-principal")
            echo "Authenticating Azure service principal: $application"
            az login --service-principal -u "$application" -p "$password" --tenant "$tenant"
            az account set --subscription "$subscription"
            ;;
        "azure-personal-account")
            echo "Authenticating Azure personal account: $email"
            az login -u "$email" -p "$password"
            if [ -n "$subscription" ]; then
                az account set --subscription "$subscription"
            fi
            ;;
        *)
            echo "Error: Unsupported Azure authentication type $type"
            return 1
            ;;
    esac
}
