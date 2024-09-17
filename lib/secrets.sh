#!/bin/bash

# Include utility functions and worker config utilities
# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Dynamically source the required provider-specific modules
source_provider_module() {
    local provider="$1"
    local module_path="/usr/local/lib/secrets/${provider}.sh"

    if [[ -f "$module_path" ]]; then
        # shellcheck source=/usr/local/lib/secrets/${provider}.sh disable=SC1091
        source "$module_path"
        log_info "Loaded module for provider: $provider"
    else
        log_warn "No module found for provider: $provider"
    fi
}

# Fetch secrets and set them as environment variables
fetch_secrets() {
    local secrets_json="$1"
    
    log_info "Fetching secrets and setting them as environment variables."

    if [[ -z "$secrets_json" || "$secrets_json" == "null" ]]; then
        log_info "No worker secrets found in the configuration."
        return 0
    fi

    # Create a temporary file to store environment variables
    local secrets_env_file
    secrets_env_file=$(mktemp /tmp/secret_vars.XXXXXX)
    echo "# Secrets environment variables" > "$secrets_env_file"

    # Process each secret in the JSON object
    echo "$secrets_json" | jq -c 'to_entries[]' | while IFS= read -r secret; do
        local name url value provider secret_name key_vault_name
        name=$(echo "$secret" | jq -r '.key')
        url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")

        # Extract provider from the URL (first part before '/')
        provider=$(echo "$url" | cut -d '/' -f 1)

        # Handle secrets based on the provider
        case "$provider" in
            gcp)
                # Extract secret name and pass to GCP resolver
                key_vault_name=$(echo "$url" | cut -d '/' -f 2)
                secret_name=$(echo "$url" | cut -d '/' -f 3)
                if [[ -z "$secret_name" ]]; then
                    log_error "Invalid GCP secret name: $url"
                    continue
                fi
                ;;
            azure|bitwarden)
                # Extract key vault and secret name
                key_vault_name=$(echo "$url" | cut -d '/' -f 2)
                secret_name=$(echo "$url" | cut -d '/' -f 3)
                if [[ -z "$key_vault_name" || -z "$secret_name" ]]; then
                    log_error "Invalid secret format for $provider: $url"
                    continue
                fi
                ;;
            *)
                log_warn "Unsupported provider: $provider"
                continue
                ;;
        esac

        # Source the provider module dynamically
        source_provider_module "$provider"

        # Determine the resolve function for the provider
        local resolve_function="resolve_${provider}_secret"
        if command -v "$resolve_function" > /dev/null; then
            value=$("$resolve_function" "$key_vault_name" "$secret_name")
        else
            log_warn "No resolve function found for provider: $provider"
            continue
        fi

        # Export the secret as an environment variable
        if [[ -n "$value" ]]; then
            echo "export $name=\"$value\"" >> "$secrets_env_file"
            log_info "Resolved secret for $name from $provider."
        else
            log_error "Failed to resolve secret for $name from $provider."
        fi
    done

    # Source the environment file if it exists
    if [[ -s "$secrets_env_file" ]]; then
        set -a
        # shellcheck disable=SC1090
        source "$secrets_env_file"
        set +a
        log_info "Secrets environment variables sourced successfully."
    else
        log_error "No secrets were written to the environment file."
        return 1
    fi

    clean_up_files "$secrets_env_file"
}

# Clean up temporary files
clean_up_files() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            rm -f "$file"
            log_info "Cleaned up temporary file: $file"
        else
            log_warn "Temporary file not found for cleanup: $file"
        fi
    done
}

# Example usage:
# fetch_secrets '{"TEST": "gcp/new_relic_api_key"}'
