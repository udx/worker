#!/bin/sh

# Function to redact sensitive parts of the logs
redact_secret() {
    echo "$1" | sed -E 's/([A-Za-z0-9_-]{3})[A-Za-z0-9_-]+([A-Za-z0-9_-]{3})/\1*********\2/g'
}

# Function to resolve secrets from Azure Key Vault
resolve_azure_secret() {
    local secret_url=$1
    az keyvault secret show --id "$secret_url" --query "value" -o tsv
}

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    echo "Fetching secrets"
    
    # Define the path to your YAML file
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    # Check if the file exists
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    # Ensure the secrets_env.sh file exists
    SECRETS_ENV_FILE="/home/$USER/.cd/configs/secrets_env.sh"
    touch $SECRETS_ENV_FILE
    echo "# Secrets environment variables" > $SECRETS_ENV_FILE
    
    # Extract secret URLs and resolve them
    SECRETS_JSON=$(yq e -o=json '.config.workerSecrets' "$WORKER_CONFIG")
    echo "Extracted secrets JSON: $SECRETS_JSON"

    echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while read -r secret; do
        name=$(echo "$secret" | jq -r '.key')
        url=$(echo "$secret" | jq -r '.value')

        echo "Resolving secret for $name"
        
        case $url in
            https://*.vault.azure.net/*)
                value=$(resolve_azure_secret "$url")
                ;;
            *)
                echo "Unsupported secret URL: $(redact_secret "$url")"
                value=""
                ;;
        esac

        if [ -n "$value" ]; then
            echo "export $name=\"$value\"" >> $SECRETS_ENV_FILE
            echo "Secret $name resolved and set as environment variable."
        else
            echo "Failed to resolve secret for $name"
        fi
    done
    
    echo "Secrets fetched and written to $SECRETS_ENV_FILE"
}