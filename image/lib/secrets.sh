#!/bin/sh

# Include specific secret resolving scripts
. /usr/local/lib/secrets/azure.sh
. /usr/local/lib/secrets/bitwarden.sh

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact passwords in the logs
redact_password() {
    echo "$1" | sed -E 's/("password":\s*")[^"]+/\1*********/g'
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
            bitwarden://*)
                bitwarden_login
                value=$(resolve_bitwarden_secret "$(echo "$url" | cut -d '/' -f 3)")
                if [ $? -ne 0 ]; then
                    echo "Error resolving Bitwarden secret for $name: $(redact_sensitive_urls "$url")" >&2
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
    . $SECRETS_ENV_FILE
    
    echo "[INFO] Secrets fetched and written to $SECRETS_ENV_FILE"
}
