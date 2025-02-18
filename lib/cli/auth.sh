#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh
source ${WORKER_LIB_DIR}/auth.sh

# Show help for auth command
auth_help() {
    cat << EOF
Manage authentication and credentials

Usage: worker auth [command]

Available Commands:
  status      Show authentication status for all providers
  test        Test authentication for all or specific provider
  refresh     Refresh credentials
  rotate      Rotate credentials (if supported by provider)

Examples:
  worker auth status
  worker auth test aws
  worker auth refresh
  worker auth rotate --provider aws
EOF
}

# Show authentication status
show_auth_status() {
    log_info "Auth" "Checking authentication status..."
    
    # Check each provider's status
    for provider in aws gcp azure bitwarden; do
        if is_provider_configured "$provider"; then
            log_success "Auth" "$provider: Configured and authenticated"
        else
            log_warn "Auth" "$provider: Not configured"
        fi
    done
}

# Test authentication
test_auth() {
    local provider=$1
    
    if [ -z "$provider" ]; then
        # Test all configured providers
        for p in aws gcp azure bitwarden; do
            if is_provider_configured "$p"; then
                test_provider_auth "$p"
            fi
        done
    else
        # Test specific provider
        if is_provider_configured "$provider"; then
            test_provider_auth "$provider"
        else
            log_error "Auth" "Provider $provider is not configured"
            return 1
        fi
    fi
}

# Refresh credentials
refresh_auth() {
    log_info "Auth" "Refreshing credentials..."
    
    # Re-run authentication for all configured providers
    local actors_json
    actors_json=$(get_config_section "$(load_and_parse_config)" "actors")
    
    if [ -n "$actors_json" ]; then
        if authenticate_actors "$actors_json"; then
            log_success "Auth" "Successfully refreshed credentials"
        else
            log_error "Auth" "Failed to refresh credentials"
            return 1
        fi
    else
        log_warn "Auth" "No actors configured"
        return 1
    fi
}

# Rotate credentials
rotate_auth() {
    local provider=$1
    
    if [ -z "$provider" ]; then
        log_error "Auth" "Provider is required for credential rotation"
        return 1
    fi
    
    if ! is_provider_configured "$provider"; then
        log_error "Auth" "Provider $provider is not configured"
        return 1
    fi
    
    # Call provider-specific rotation function
    if rotate_provider_credentials "$provider"; then
        log_success "Auth" "Successfully rotated credentials for $provider"
    else
        log_error "Auth" "Failed to rotate credentials for $provider"
        return 1
    fi
}

# Handle auth commands
auth_handler() {
    local cmd=$1
    shift
    
    case $cmd in
        status)
            show_auth_status
            ;;
        test)
            test_auth "$1"
            ;;
        refresh)
            refresh_auth
            ;;
        rotate)
            rotate_auth "$1"
            ;;
        help)
            auth_help
            ;;
        *)
            log_error "Auth" "Unknown command: $cmd"
            auth_help
            exit 1
            ;;
    esac
}
