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
    
    # Load config once and extract actors section
    local config actors
    config=$(load_and_parse_config)
    actors=$(get_config_section "$config" "actors")
    
    # Function to check a specific provider
    check_provider_status() {
        local provider=$1
        local status="Not configured"
        local types=""
        
        # Get provider's actors
        local provider_actors
        provider_actors=$(echo "$actors" | jq -r "[.[] | select(.type | startswith(\"$provider\"))]" 2>/dev/null)
        
        if [ -n "$provider_actors" ] && [ "$provider_actors" != "[]" ]; then
            types=$(echo "$provider_actors" | jq -r '.[].type' 2>/dev/null | tr '\n' ' ')
            
            # First check if provider has credentials
            if is_provider_configured "$provider" "$provider_actors"; then
                # Then check if it's authenticated
                if check_provider_auth "$provider"; then
                    status="Authenticated"
                    state="active"
                else
                    status="Needs re-auth"
                    state="needs_reauth"
                fi
            else
                status="Not configured"
                state="missing_creds"
            fi
        else
            status="Not configured"
            state="not_configured"
        fi
        
        # Output status based on format
        if [ "$format" = "json" ]; then
            [ -n "$json_output" ] && [ "$json_output" != "[" ] && json_output+=","
            json_output+=$(jq -n \
                --arg provider "$provider" \
                --arg state "$state" \
                --arg status "$status" \
                --arg types "$types" \
                '{provider: $provider, state: $state, status: $status, types: $types}')
        else
            case "$state" in
                "active") log_success "Auth" "$provider: $status" ;;
                "needs_reauth") log_info "Auth" "$provider: $status" ;;
                "missing_creds") log_warn "Auth" "$provider: $status" ;;
                "not_configured") log_info "Auth" "$provider: $status" ;;
            esac
        fi
    }
    
    # Check status for specific provider or all providers
    if [ -n "$target_provider" ]; then
        check_provider_status "$target_provider"
    else
        check_provider_status "aws"
        check_provider_status "gcp"
        check_provider_status "azure"
        check_provider_status "bitwarden"
    fi
    
    # Close JSON array if json format
    if [ "$format" = "json" ]; then
        json_output+="]"
        echo "$json_output"
    fi
}

# Login to provider(s)
login_provider() {
    local target_provider=$1
    log_info "Auth" "Authenticating providers..."
    
    # Load config once and extract actors section
    local config actors
    config=$(load_and_parse_config)
    actors=$(get_config_section "$config" "actors")
    
    if [[ -z "$actors" || "$actors" == "null" ]]; then
        log_warn "Auth" "No providers found in configuration"
        return 1
    fi
    
    # Filter actors by provider if specified
    if [[ -n "$target_provider" ]]; then
        actors=$(echo "$actors" | jq -r "[.[] | select(.type | startswith(\"$target_provider\"))]")
        if [[ "$actors" == "[]" ]]; then
            log_warn "Auth" "$target_provider: Not configured"
            return 1
        fi
    fi
    
    # Use the same authentication flow as entrypoint
    if authenticate_actors "$actors"; then
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
            # Azure CLI can return non-zero exit code even when it succeeds
            # so we check if the output contains valid JSON
            if output=$(az account show 2>/dev/null) && echo "$output" | jq empty &>/dev/null; then
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
