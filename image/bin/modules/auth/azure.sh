#!/bin/sh

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor=$1
    local type=$(echo "$actor" | yq e '.value.type' -)
    local subscription=$(echo "$actor" | yq e '.value.subscription' -)
    local tenant=$(echo "$actor" | yq e '.value.tenant' -)
    local application=$(echo "$actor" | yq e '.value.application' -)
    local password=$(echo "$actor" | yq e '.value.password' -)
    local email=$(echo "$actor" | yq e '.value.email' -)
    
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
