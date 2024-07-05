#!/bin/sh

# Include specific secret resolving scripts
. /usr/local/lib/secrets/azure.sh

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact sensitive URLs
redact_sensitive_urls() {
    echo "$1" | sed -E 's/(https:\/\/[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)([A-Za-z0-9\/_-]*)/\1.*********\2.*********\3/g'
}

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    echo "[INFO] Fetching secrets"
    
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "Error: YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    SECRETS_ENV_FILE="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > $SECRETS_ENV_FILE
    
    SECRETS_JSON=$(yq e -o=json '.config.workerSecrets' "$WORKER_CONFIG")
    echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while read -r secret; do
        name=$(echo "$secret" | jq -r '.key')
        url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")

        echo "[INFO] Resolved URL for $name: $(redact_sensitive_urls "$url")"
        
        case $url in
            https://*.vault.azure.net/*)
                value=$(resolve_azure_secret "$url")
                if [ $? -ne 0 ]; then
                    echo "Error resolving Azure secret for $name: $(redact_sensitive_urls "$url")" >&2
                    value=""
                fi
                ;;
            *)
                echo "Unsupported secret URL: $(redact_sensitive_urls "$url")" >&2
                value=""
                ;;
        esac

        if [ -n "$value" ]; then
            echo "export $name=\"$value\"" >> $SECRETS_ENV_FILE
            echo "[INFO] Secret $name resolved and set as environment variable." >&2
        else
            echo "[ERROR] Failed to resolve secret for $name" >&2
        fi
    done

    echo "[INFO] Sourcing secrets from $SECRETS_ENV_FILE" >&2
    set -a
    . $SECRETS_ENV_FILE
    set +a
    
    echo "[INFO] Secrets fetched and written to $SECRETS_ENV_FILE"
    
    # Verify DOCKER_IMAGE_NAME
    if [ -z "$DOCKER_IMAGE_NAME" ]; then
        echo "[ERROR] DOCKER_IMAGE_NAME is not set after sourcing secrets"
    else
        echo "[INFO] DOCKER_IMAGE_NAME is set to $DOCKER_IMAGE_NAME after sourcing secrets"
    fi
}
