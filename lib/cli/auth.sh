#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh
source ${WORKER_LIB_DIR}/auth.sh

# Show help for auth command
auth_help() {
    cat << EOF
Manage authentication and credentials

Usage: worker auth [command] [provider] [options]

Available Commands:
  status      Show authentication status for all or specific provider
  login       Re-authenticate with provider(s) using available credentials
  logout      Log out from provider(s)

Options:
  --format    Output format for status command (e.g. json)

Examples:
  worker auth status              # Show status of all providers
  worker auth status azure       # Show status of Azure only
  worker auth status --format json # Show status in JSON format
  worker auth login              # Re-auth all providers with available creds
  worker auth login azure  # Re-auth Azure only
  worker auth logout       # Log out from all providers
EOF
}

# Description: Display authentication status for all cloud providers
# Example: worker auth status [--format json]
show_auth_status() {
    local target_provider=$1
    local format=$2
    
    if [ "$format" != "json" ]; then
        log_info "Auth" "Checking authentication status..."
    fi
    
    # Initialize JSON array if json format
    local json_output="["
    
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
        
        # Prepare status message and state
        local status_msg state
        if [ "$has_env_creds" = true ] || [ "$has_config_creds" = true ]; then
            if [ "$is_authenticated" = true ]; then
                status_msg="Active session${types:+ (actors: $types)}"
                state="active"
            else
                status_msg="Has credentials${types:+ (actors: $types)}, needs re-auth"
                state="needs_reauth"
            fi
        else
            if [ -n "$types" ]; then
                status_msg="Missing credentials (actors: $types)"
                state="missing_creds"
            else
                status_msg="Not configured"
                state="not_configured"
            fi
        fi

        # Output based on format
        if [ "$format" = "json" ]; then
            [ "$json_output" != "[" ] && json_output+=","
            json_output+="{\"provider\":\"$provider\",\"state\":\"$state\",\"message\":\"$status_msg\"}"
        else
            case "$state" in
                "active") log_success "Auth" "$provider: $status_msg" ;;
                "needs_reauth") log_info "Auth" "$provider: $status_msg" ;;
                "missing_creds") log_warn "Auth" "$provider: $status_msg" ;;
                "not_configured") log_info "Auth" "$provider: $status_msg" ;;
            esac
        fi
    }
    
    if [ -n "$target_provider" ]; then
        check_provider_status "$target_provider"
    else
        for provider in aws gcp azure bitwarden; do
            check_provider_status "$provider"
        done
    fi

    # Close and output JSON if json format
    if [ "$format" = "json" ]; then
        json_output+="]"
        echo "$json_output"
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
    shift
    
    case $cmd in
        status)
            local provider=""
            local format=""
            
            # Parse arguments
            while [ $# -gt 0 ]; do
                case "$1" in
                    --format)
                        format="$2"
                        shift 2
                        ;;
                    --*)
                        log_error "CLI" "Unknown option: $1"
                        return 1
                        ;;
                    *)
                        if [ -z "$provider" ]; then
                            provider="$1"
                        else
                            log_error "CLI" "Unexpected argument: $1"
                            return 1
                        fi
                        shift
                        ;;
                esac
            done
            
            show_auth_status "$provider" "$format"
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
