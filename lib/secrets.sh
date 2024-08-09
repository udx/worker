#!/bin/bash

# Function to source a secrets module if it exists
source_secrets_module() {
    local script_path="$1"
    if [ -f "$script_path" ]; then
        # shellcheck source=/dev/null
        source "$script_path"
    else
        echo "[INFO] Secrets module $script_path is not enabled."
    fi
}

# Attempt to source the required secrets modules
source_secrets_module /usr/local/lib/secrets/aws.sh
source_secrets_module /usr/local/lib/secrets/azure.sh
source_secrets_module /usr/local/lib/secrets/bitwarden.sh
source_secrets_module /usr/local/lib/secrets/gcp.sh

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact sensitive URLs
redact_sensitive_urls() {
    echo "$1" | sed -E 's|(https://[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)([A-Za-z0-9/-]*)|\1.*********\2.*********\3|g'
}

# Function to detect the provider from the URL and resolve the secret
resolve_secret() {
    local name="$1"
    local url="$2"
    local value
    
    echo "[INFO] Resolved URL for $name: $(redact_sensitive_urls "$url")"
    
    case $url in
        https://*.vault.azure.net/*)
            if ! value=$(resolve_azure_secret "$url"); then
                echo "[ERROR] Error resolving Azure secret for $name: $(redact_sensitive_urls "$url")" >&2
                value=""
            fi
        ;;
        https://secretmanager.googleapis.com/*)
            if ! value=$(resolve_gcp_secret "$url"); then
                echo "[ERROR] Error resolving GCP secret for $name: $(redact_sensitive_urls "$url")" >&2
                value=""
            fi
        ;;
        https://secretsmanager.*.amazonaws.com/*)
            if ! value=$(resolve_aws_secret "$url"); then
                echo "[ERROR] Error resolving AWS secret for $name: $(redact_sensitive_urls "$url")" >&2
                value=""
            fi
        ;;
        bitwarden://*)
            if ! value=$(resolve_bitwarden_secret "$url"); then
                echo "[ERROR] Error resolving Bitwarden secret for $name: $(redact_sensitive_urls "$url")" >&2
                value=""
            fi
        ;;
        *)
            echo "[ERROR] Unsupported secret URL: $(redact_sensitive_urls "$url")" >&2
            value=""
        ;;
    esac
    
    echo "$value"
}

# Function to fetch secrets and set them as environment variables
fetch_secrets() {
    echo "[INFO] Fetching secrets"
    
    WORKER_CONFIG="/home/$USER/.cd/configs/worker.yml"
    
    if [ ! -f "$WORKER_CONFIG" ]; then
        echo "[ERROR] YAML configuration file not found at $WORKER_CONFIG"
        return 1
    fi
    
    SECRETS_ENV_FILE="/tmp/secret_vars.sh"
    echo "# Secrets environment variables" > "$SECRETS_ENV_FILE"
    
    SECRETS_JSON=$(yq e -o=json '.config.workerSecrets' "$WORKER_CONFIG")
    
    if [ -z "$SECRETS_JSON" ]; then
        echo "[INFO] No worker secrets found in the configuration"
    else
        echo "$SECRETS_JSON" | jq -c 'to_entries[]' | while read -r secret; do
            name=$(echo "$secret" | jq -r '.key')
            url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")
            
            value=$(resolve_secret "$name" "$url")
            
            if [ -n "$value" ]; then
                echo "export $name=\"$value\"" >> "$SECRETS_ENV_FILE"
                echo "[INFO] Secret $name resolved and set as environment variable." >&2
            else
                echo "[ERROR] Failed to resolve secret for $name" >&2
            fi
        done
        
        set -a
        if [ -f "$SECRETS_ENV_FILE" ]; then
            # shellcheck source=/dev/null
            source "$SECRETS_ENV_FILE"
        else
            echo "[ERROR] Secrets environment file not found: $SECRETS_ENV_FILE"
            return 1
        fi
        set +a
    fi
}
