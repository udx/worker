#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh
source ${WORKER_LIB_DIR}/auth.sh

# Show help for auth command
auth_help() {
    cat << EOF
Manage authentication and credentials

Usage: worker auth [command] [provider]

Available Commands:
  status      Show authentication status for all or specific provider
  login       Re-authenticate with provider(s) using available credentials
  logout      Log out from provider(s)

Examples:
  worker auth status        # Show status of all providers
  worker auth status azure # Show status of Azure only
  worker auth login        # Re-auth all providers with available creds
  worker auth login azure  # Re-auth Azure only
  worker auth logout       # Log out from all providers
EOF
}

# Description: Display authentication status for all cloud providers
# Example: worker auth status
show_auth_status() {
    local target_provider=$1
    log_info "Auth" "Checking authentication status..."
    
    # Function to check a specific provider
    check_provider_status() {
        local provider=$1
        local has_env_creds=false
        local has_config_creds=false
        local types=""
        
        # First check env vars from config
        local env_vars
        mapfile -t env_vars < <(get_provider_env_vars "$provider")
        
        for env_var in "${env_vars[@]}"; do
            if [ -n "${!env_var}" ]; then
                has_env_creds=true
                break
            fi
        done
        
        # Then check config
        local config
        config=$(load_and_parse_config)
        
        if echo "$config" | jq -e '.config.actors' >/dev/null 2>&1; then
            local actors
            actors=$(echo "$config" | jq -r ".config.actors[] | select(.type | startswith(\"$provider-\"))" 2>/dev/null)
            
            if [ -n "$actors" ] && [ "$actors" != "null" ]; then
                types=$(echo "$actors" | jq -r '.type' 2>/dev/null | grep . | tr '\n' ' ')
                
                while IFS= read -r actor; do
                    [ -z "$actor" ] && continue
                    
                    local creds
                    creds=$(echo "$actor" | jq -r '.creds' 2>/dev/null)
                    [ "$creds" = "null" ] && continue
                    
                    # Evaluate creds as a reference to an environment variable
                    if [[ "$creds" =~ ^\$\{(.+)\}$ ]]; then
                        local env_var_name="${BASH_REMATCH[1]}"
                        creds="${!env_var_name}"
                    fi
                    
                    if [ -n "$creds" ]; then
                        has_config_creds=true
                        break
                    fi
                done <<< "$actors"
            fi
        fi
        
        # Check if currently authenticated
        local is_authenticated=false
        if check_provider_auth "$provider"; then
            is_authenticated=true
        fi
        
        # Show status based on env vars and config
        if [ "$has_env_creds" = true ] || [ "$has_config_creds" = true ]; then
            if [ "$is_authenticated" = true ]; then
                log_success "Auth" "$provider: Active session${types:+ (actors: $types)}"
            else
                log_info "Auth" "$provider: Has credentials${types:+ (actors: $types)}, needs re-auth"
            fi
        else
            if [ -n "$types" ]; then
                log_warn "Auth" "$provider: Missing credentials (actors: $types)"
            else
                log_info "Auth" "$provider: Not configured"
            fi
        fi
    }
    
    if [ -n "$target_provider" ]; then
        check_provider_status "$target_provider"
    else
        for provider in aws gcp azure bitwarden; do
            check_provider_status "$provider"
        done
    fi
}

# Login to provider(s)
login_provider() {
    local target_provider=$1
    log_info "Auth" "Authenticating providers..."
    
    # Load config and get actors
    local config actors_json
    config=$(load_and_parse_config)
    actors_json=$(echo "$config" | jq -r '.config.actors')
    
    if [[ -z "$actors_json" || "$actors_json" == "null" ]]; then
        log_warn "Auth" "No providers found in configuration"
        return 1
    fi
    
    # Filter actors by provider if specified
    if [[ -n "$target_provider" ]]; then
        actors_json=$(echo "$config" | jq -r ".config.actors | map(select(.type | startswith(\"$target_provider-\")))") 
        if [[ "$actors_json" == "[]" ]]; then
            log_warn "Auth" "$target_provider: Not configured"
            return 1
        fi
    fi
    
    # Use the same authentication flow as entrypoint
    if authenticate_actors "$actors_json"; then
        log_success "Auth" "Authentication complete"
        return 0
    else
        log_warn "Auth" "No providers were authenticated"
        return 1
    fi
}

# Logout from provider(s)
logout_provider() {
    local target_provider=$1
    log_info "Auth" "Logging out providers..."
    
    # Source cleanup utilities
    source ${WORKER_LIB_DIR}/cleanup.sh
    
    # Function to logout from a specific provider
    do_provider_logout() {
        local provider=$1
        
        case "$provider" in
            aws)
                cleanup_provider "aws" "aws sso logout" "aws sso list-accounts" "AWS"
                ;;
            azure)
                cleanup_provider "az" "az logout" "az account show" "Azure"
                ;;
            gcp)
                cleanup_provider "gcloud" "gcloud auth revoke --all" "gcloud auth list" "GCP"
                ;;
            bitwarden)
                cleanup_provider "bw" "bw logout --force" "bw status" "Bitwarden"
                ;;
        esac
    }
    
    if [ -n "$target_provider" ]; then
        do_provider_logout "$target_provider"
    else
        for provider in aws gcp azure bitwarden; do
            do_provider_logout "$provider"
        done
    fi
}



# Check if a provider is currently authenticated
check_provider_auth() {
    local provider=$1
    
    case "$provider" in
        aws)
            if aws sts get-caller-identity &>/dev/null; then
                return 0
            fi
            ;;
        azure)
            if az account show &>/dev/null; then
                return 0
            fi
            ;;
        gcp)
            if gcloud auth list --format="value(account)" 2>/dev/null | grep -q .; then
                return 0
            fi
            ;;
        bitwarden)
            if bw status | grep -q "unlocked"; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Handle auth commands
auth_handler() {
    local cmd=$1
    local provider=$2
    
    case $cmd in
        status)
            show_auth_status "$provider"
            return $?
            ;;
        login)
            login_provider "$provider"
            return $?
            ;;
        logout)
            logout_provider "$provider"
            return $?
            ;;
        "" | help)
            auth_help
            return 0
            ;;
        *)
            log_error "CLI" "Unknown command: auth"
            auth_help
            return 1
            ;;
    esac
}
