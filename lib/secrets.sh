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
    local secrets_json="$1"  # The .config.secrets section is passed as an argument

    log_info "Fetching secrets and setting them as environment variables."

    local secrets_env_file
    secrets_env_file=$(mktemp /tmp/secret_vars.XXXXXX)
    echo "# Secrets environment variables" > "$secrets_env_file"

    if [[ -z "$secrets_json" || "$secrets_json" == "null" ]]; then
        log_info "No worker secrets found in the configuration."
        clean_up_files "$secrets_env_file"
        return 0
    fi

    echo "$secrets_json" | jq -c 'to_entries[]' | while IFS= read -r secret; do
        local name url value provider key_vault_name secret_name
        name=$(echo "$secret" | jq -r '.key')
        url=$(resolve_env_vars "$(echo "$secret" | jq -r '.value')")

        # Extract provider, key_vault_name, and secret_name from the URL
        provider=$(echo "$url" | cut -d '/' -f 1)
        key_vault_name=$(echo "$url" | cut -d '/' -f 2)
        secret_name=$(echo "$url" | cut -d '/' -f 3)

        # Ensure provider, key_vault_name, and secret_name are all set
        if [[ -z "$provider" || -z "$key_vault_name" || -z "$secret_name" ]]; then
            log_error "Invalid secret format: $url"
            continue
        fi

        source_provider_module "$provider"

        local resolve_function="resolve_${provider}_secret"
        if command -v "$resolve_function" > /dev/null; then
            value=$("$resolve_function" "$key_vault_name" "$secret_name")
        else
            log_warn "No resolve function found for provider: $provider"
            continue
        fi

        if [[ -n "$value" ]]; then
            echo "export $name=\"$value\"" >> "$secrets_env_file"
            log_info "Resolved secret for $name from $provider."
        else
            log_error "Failed to resolve secret for $name from $provider."
        fi
    done

    if [[ -f "$secrets_env_file" ]]; then
        set -a
        # shellcheck source=/tmp/secret_vars.XXXXXX disable=SC1091
        source "$secrets_env_file"
        set +a
        log_info "Secrets environment variables sourced successfully."
    else
        log_error "Secrets environment file not found: $secrets_env_file"
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
