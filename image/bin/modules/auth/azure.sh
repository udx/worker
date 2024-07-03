#!/bin/sh

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor=$1
    local type=$(echo "$actor" | jq -r '.type')
    local subscription=$(echo "$actor" | jq -r '.subscription')
    local tenant=$(echo "$actor" | jq -r '.tenant')
    local application=$(echo "$actor" | jq -r '.application')
    local password=$(echo "$actor" | jq -r '.password')
    local email=$(echo "$actor" | jq -r '.email')

    echo "Actor type: $type"
    echo "Subscription: $subscription"
    echo "Tenant: $tenant"
    echo "Application: $application"
    # echo "Password: $password"
    echo "Email: $email"

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
