#!/bin/sh


# Function to redact sensitive parts of the logs
redact_secret() {
    echo "$1" | sed -E 's/([A-Za-z0-9_-]{3})[A-Za-z0-9_-]+([A-Za-z0-9_-]{3})/\1*********\2/g'
}

# Function to authenticate Azure accounts
azure_authenticate() {
    local actor=$1
    local type=$(echo "$actor" | jq -r '.type')
    local subscription=$(echo "$actor" | jq -r '.subscription')
    local tenant=$(echo "$actor" | jq -r '.tenant')
    local application=$(echo "$actor" | jq -r '.application')
    local password=$(echo "$actor" | jq -r '.password')
    local email=$(echo "$actor" | jq -r '.email')

    case $type in
        "azure-service-principal")
            echo "Authenticating Azure service principal: $application"
            az login --service-principal -u "$application" -p "$password" --tenant "$tenant"
            az account set --subscription "$subscription"
            ;;
        "azure-personal-account")
            echo "Authenticating Azure personal account: $(redact_secret "$email")"
            az login -u "$email" -p "$password"
            az account set --subscription "$subscription"
            ;;
        *)
            echo "Error: Unsupported actor type $type"
            return 1
            ;;
    esac
}

# Function to authenticate actors
authenticate_actors() {
    echo "Authenticating actors"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Extract actor information and authenticate
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    echo "Extracted actors JSON: $(redact_secret "$ACTORS_JSON")"

    echo "$ACTORS_JSON" | jq -c '.[]' | while read -r actor; do
        type=$(echo "$actor" | jq -r '.type')
        echo "Extracted actor type: $type"
        case $type in
            "azure-service-principal" | "azure-personal-account")
                azure_authenticate "$actor"
            ;;
            "gcp-service-account")
                gcp_authenticate "$actor"
            ;;
            "aws-role")
                aws_authenticate "$actor"
            ;;
            *)
                echo "Error: Unsupported actor type $type"
            ;;
        esac
    done
}
