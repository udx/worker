#!/bin/sh

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact passwords in the logs
redact_password() {
    echo "$1" | sed -E 's/("password":\s*")[^"]+/\1*********/g'
}

# Function to authenticate Azure service principal
authenticate_azure_service_principal() {
    local subscription=$1
    local tenant=$2
    local application=$3
    local password=$4

    echo "Authenticating Azure service principal: $application"
    az login --service-principal -u "$application" -p "$password" --tenant "$tenant"
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

    # Extract actor configurations and resolve them
    ACTORS_JSON=$(yq e -o=json '.config.workerActors' "$WORKER_CONFIG")
    echo "Extracted actors JSON: $(redact_password "$ACTORS_JSON")"

    echo "$ACTORS_JSON" | jq -c 'to_entries[]' | while read -r actor; do
        type=$(echo "$actor" | jq -r '.value.type')
        subscription=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.subscription')")
        tenant=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.tenant')")
        application=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.application')")
        password=$(resolve_env_vars "$(echo "$actor" | jq -r '.value.password')")

        echo "Resolved subscription: $subscription"
        echo "Resolved tenant: $tenant"
        echo "Resolved application: $application"

        case $type in
            azure-service-principal)
                authenticate_azure_service_principal "$subscription" "$tenant" "$application" "$password"
                ;;
            *)
                echo "Unsupported actor type: $type"
                ;;
        esac
    done
}
