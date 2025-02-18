#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh
source ${WORKER_LIB_DIR}/worker_config.sh

# Show help for env command
env_help() {
    cat << EOF
Manage environment variables and secrets

Usage: worker env [command]

Available Commands:
  show        Show environment variables (excludes secrets)
  set         Set an environment variable
  unset       Unset an environment variable
  reload      Reload environment from config
  status      Show environment status
  validate    Validate environment variables
  export      Export environment to file
  import      Import environment from file

Options:
  --format    Output format (text/json)
  --filter    Filter variables by prefix
  --file      File to export to or import from
  --include-secrets Include secrets in output (masked)

Examples:
  worker env show
  worker env show --format json
  worker env show --filter AWS_*
  worker env show --include-secrets
  worker env set MY_VAR "my value"
  worker env reload
EOF
}

# Show environment variables
show_environment() {
    local format=${1:-text}
    local filter=$2
    local include_secrets=${3:-false}
    
    if [ "$include_secrets" == "true" ]; then
        list_env_vars "$format"
    else
        # Only show non-secret environment variables
        if [ -f "$WORKER_ENV_FILE" ]; then
            case $format in
                json)
                    {
                        echo "{"
                        if [ -n "$filter" ]; then
                            grep "^export $filter" "$WORKER_ENV_FILE" | sed 's/export \([^=]*\)="\([^"]*\)"/  "\1": "\2",/'
                        else
                            grep "^export" "$WORKER_ENV_FILE" | sed 's/export \([^=]*\)="\([^"]*\)"/  "\1": "\2",/'
                        fi
                        echo "}" 
                    } | sed 's/,}/}/' | jq '.'
                    ;;
                text)
                    if [ -n "$filter" ]; then
                        grep "^export $filter" "$WORKER_ENV_FILE" | sed 's/export \([^=]*\)="\([^"]*\)"/\1=\2/'
                    else
                        grep "^export" "$WORKER_ENV_FILE" | sed 's/export \([^=]*\)="\([^"]*\)"/\1=\2/'
                    fi
                    ;;
                *)
                    log_error "Env" "Unknown format: $format"
                    return 1
                    ;;
            esac
        else
            log_error "Env" "Environment file not found"
            return 1
        fi
    fi
}

# Set environment variable
set_environment() {
    local name=$1
    local value=$2
    
    if [ -z "$name" ] || [ -z "$value" ]; then
        log_error "Env" "Both variable name and value are required"
        return 1
    fi
    
    # Validate variable name
    if ! [[ $name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        log_error "Env" "Invalid variable name: $name"
        return 1
    fi
    
    # Add to environment file
    if [ -f "$WORKER_ENV_FILE" ]; then
        # Remove existing declaration if any
        sed -i "/^export $name=/d" "$WORKER_ENV_FILE"
        # Add new declaration
        echo "export $name=\"$value\"" >> "$WORKER_ENV_FILE"
        # Export in current session
        export "$name=$value"
        log_success "Env" "Set $name to '$value'"
    else
        log_error "Env" "Environment file not found"
        return 1
    fi
}

# Unset environment variable
unset_environment() {
    local name=$1
    
    if [ -z "$name" ]; then
        log_error "Env" "Variable name is required"
        return 1
    fi
    
    if [ -n "${!name}" ]; then
        unset "$name"
        log_success "Env" "Unset $name"
    else
        log_warn "Env" "Variable $name is not set"
    fi
}

# Export environment variables
export_environment() {
    local file=$1
    local filter=$2
    
    if [ -z "$file" ]; then
        log_error "Env" "Output file is required"
        return 1
    fi
    
    # Export variables
    if [ -n "$filter" ]; then
        env | grep "^$filter" > "$file"
    else
        env > "$file"
    fi
    
    log_success "Env" "Environment variables exported to $file"
}

# Import environment variables
import_environment() {
    local file=$1
    
    if [ -z "$file" ]; then
        log_error "Env" "Input file is required"
        return 1
    fi
    
    if [ ! -f "$file" ]; then
        log_error "Env" "File not found: $file"
        return 1
    fi
    
    # Import variables
    while IFS='=' read -r key value; do
        if [ -n "$key" ]; then
            export "$key=$value"
        fi
    done < "$file"
    
    log_success "Env" "Environment variables imported from $file"
}

# Validate environment variables
validate_environment() {
    local config
    config=$(load_and_parse_config)
    
    if [ -z "$config" ]; then
        log_error "Env" "Failed to load configuration"
        return 1
    fi
    
    # Extract required variables from config
    local required_vars
    required_vars=$(echo "$config" | yq eval '.config.env | keys' -)
    
    local failed=0
    while IFS= read -r var; do
        if [ -z "${!var}" ]; then
            log_error "Env" "Required variable $var is not set"
            failed=1
        fi
    done <<< "$required_vars"
    
    if [ $failed -eq 0 ]; then
        log_success "Env" "All required environment variables are set"
    else
        return 1
    fi
}

# Generate environment template
generate_template() {
    local config
    config=$(load_and_parse_config)
    
    if [ -z "$config" ]; then
        log_error "Env" "Failed to load configuration"
        return 1
    fi
    
    echo "# Worker Environment Variables"
    echo "# Generated on $(date)"
    echo
    
    # Extract variables from config
    echo "$config" | yq eval '.config.env | to_entries | .[] | "# " + .key + "\n" + .key + "=\"" + .value + "\""' -
}

# Reset environment
reset_environment() {
    # Clear all non-system variables
    local system_vars="HOME|USER|PATH|SHELL|TERM|LANG|PWD"
    
    # Get all variables except system ones
    local vars_to_unset
    vars_to_unset=$(env | grep -vE "^($system_vars)=")
    
    while IFS='=' read -r key _; do
        if [ -n "$key" ]; then
            unset "$key"
        fi
    done <<< "$vars_to_unset"
    
    # Reconfigure environment
    if configure_environment; then
        log_success "Env" "Environment reset to default state"
    else
        log_error "Env" "Failed to reset environment"
        return 1
    fi
}

# Parse command line arguments
parse_args() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                format=$2
                shift 2
                ;;
            --filter)
                filter=$2
                shift 2
                ;;
            --file)
                file=$2
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${args[@]}"
}

# Show environment status
show_status() {
    local format=${1:-text}
    
    local env_file_exists=false
    local secrets_file_exists=false
    local env_count=0
    local secrets_count=0
    
    [ -f "$WORKER_ENV_FILE" ] && env_file_exists=true
    [ -f "$WORKER_SECRETS_FILE" ] && secrets_file_exists=true
    
    if [ "$env_file_exists" = true ]; then
        env_count=$(grep -c "^export" "$WORKER_ENV_FILE" || echo 0)
    fi
    
    if [ "$secrets_file_exists" = true ]; then
        secrets_count=$(grep -c "^export" "$WORKER_SECRETS_FILE" || echo 0)
    fi
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"environment\": {"
                echo "    \"file\": \"$WORKER_ENV_FILE\","
                echo "    \"exists\": $env_file_exists,"
                echo "    \"variables\": $env_count"
                echo "  },"
                echo "  \"secrets\": {"
                echo "    \"file\": \"$WORKER_SECRETS_FILE\","
                echo "    \"exists\": $secrets_file_exists,"
                echo "    \"variables\": $secrets_count"
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            echo "Environment Status:"
            echo "------------------"
            echo "Environment File: $WORKER_ENV_FILE"
            echo "  - Exists: $env_file_exists"
            echo "  - Variables: $env_count"
            echo
            echo "Secrets File: $WORKER_SECRETS_FILE"
            echo "  - Exists: $secrets_file_exists"
            echo "  - Variables: $secrets_count"
            ;;
        *)
            log_error "Env" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Handle environment commands
env_handler() {
    local cmd=$1
    shift
    
    # Parse command line arguments
    parse_args "$@"
    
    case $cmd in
        show)
            show_environment "$format" "$filter" "$include_secrets"
            ;;
        set)
            set_environment "$1" "$2"
            ;;
        unset)
            unset_environment "$1"
            ;;
        reload)
            config=$(load_and_parse_config)
            export_variables_from_config "$config"
            ;;
        status)
            show_status "$format"
            ;;
        validate)
            validate_environment
            ;;
        export)
            export_environment "$file" "$filter"
            ;;
        import)
            import_environment "$file"
            ;;
        help)
            env_help
            ;;
        *)
            log_error "Env" "Unknown command: $cmd"
            env_help
            exit 1
            ;;
    esac
}