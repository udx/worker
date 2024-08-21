#!/bin/bash
set -e

# Function to resolve environment variables
resolve_env_vars() {
    local value="$1"
    echo "${!value}"
}

# Function to check dependencies
check_dependencies() {
    command -v jq >/dev/null 2>&1 || { echo "[ERROR] jq is required but not installed." >&2; exit 1; }
    command -v az >/dev/null 2>&1 || { echo "[ERROR] Azure CLI (az) is required but not installed." >&2; exit 1; }
}

# Function to authenticate Azure accounts
azure_authenticate() {
    local config_file="$1"

    if [ ! -f "$config_file" ]; then
        echo "[ERROR] Configuration file not found: $config_file" >&2
        return 1
    fi

    local type subscription tenant application password
    type=$(jq -r '.type' "$config_file")
    subscription=$(resolve_env_vars "$(jq -r '.subscription' "$config_file")")
    tenant=$(resolve_env_vars "$(jq -r '.tenant' "$config_file")")
    application=$(resolve_env_vars "$(jq -r '.application' "$config_file")")
    password=$(resolve_env_vars "$(jq -r '.password' "$config_file")")

    check_dependencies

    case $type in
        "azure-service-principal")
            echo "[INFO] Authenticating Azure service principal..."
            if ! az login --service-principal -u "$application" -p "$password" --tenant "$tenant" >/dev/null 2>&1; then
                echo "[ERROR] Azure service principal authentication failed." >&2
                return 1
            fi
            if ! az account set --subscription "$subscription" >/dev/null 2>&1; then
                echo "[ERROR] Failed to set Azure subscription." >&2
                return 1
            fi
            ;;
        "azure-personal-account")
            echo "[INFO] Authenticating Azure personal account..."
            if ! az login -u "$application" -p "$password" >/dev/null 2>&1; then
                echo "[ERROR] Azure personal account authentication failed." >&2
                return 1
            fi
            if [ -n "$subscription" ] && ! az account set --subscription "$subscription" >/dev/null 2>&1; then
                echo "[ERROR] Failed to set Azure subscription." >&2
                return 1
            fi
            ;;
        *)
            echo "[ERROR] Unsupported Azure authentication type: $type" >&2
            return 1
            ;;
    esac
}

# Example usage
# azure_authenticate "path/to/azure_config.json"
