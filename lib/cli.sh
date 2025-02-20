#!/bin/bash

# Version information
VERSION="1.0.0"

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Dynamically source all command modules
for module in "${WORKER_LIB_DIR}/cli/"*.sh; do
    # shellcheck disable=SC1090
    source "$module"
done

# Print version information
show_version() {
    log_info "Worker CLI version $VERSION"
}

# Get available commands and their descriptions
get_available_commands() {
    local commands={}
    declare -A commands
    
    # Add built-in commands
    commands["help"]="Show help for any command"
    commands["version"]="Show version information"
    
    # Scan through CLI modules to find commands and their descriptions
    for module in "${WORKER_LIB_DIR}/cli/"*.sh; do
        if [ -f "$module" ]; then
            local name
            name=$(basename "$module" .sh)
            local description=""
            
            # Extract description from help function
            if grep -q "${name}_help()" "$module"; then
                description=$(grep -A 5 "${name}_help()" "$module" | 
                             grep -v "${name}_help()" | 
                             grep -v "^{" |
                             grep -v "cat << EOF" |
                             head -n 1 | 
                             sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
                commands[$name]="$description"
            fi
        fi
    done
    
    declare -p commands
}

# Print help information
show_help() {
    local -A commands
    eval "$(get_available_commands)"
    
    # Find the longest command name for proper padding
    local max_length=0
    for cmd in "${!commands[@]}"; do
        local len=${#cmd}
        if ((len > max_length)); then
            max_length=$len
        fi
    done
    
    # Add padding for alignment
    max_length=$((max_length + 2))
    
    cat << EOF
🚀 Welcome to UDX Worker Container!

Available Commands:
EOF
    
    # Sort commands alphabetically and display
    local sorted_commands
    mapfile -t sorted_commands < <(printf '%s\n' "${!commands[@]}" | sort)
    for cmd in "${sorted_commands[@]}"; do
        printf "  %-${max_length}s %s\n" "$cmd" "${commands[$cmd]}"
    done
    
    cat << EOF

Run any command without arguments to see its detailed help and usage information.
For example: 'worker auth' will show auth command help.
EOF
}

# Main CLI interface
if [ -z "$1" ] || [ "$1" = "help" ]; then
    show_help
    log_info "Container is ready. Run a command to start services."
    exit 0
fi

if [ "$1" = "version" ]; then
    show_version
    exit 0
fi

# Handle app commands
if [ "$1" = "app" ]; then
    # Source and load configuration for app commands
    # shellcheck disable=SC1091
    source "${WORKER_LIB_DIR}/worker_config.sh"
    config=$(load_and_parse_config)
    export_variables_from_config "$config"
    
    log_info "Starting process manager..."
    "${WORKER_LIB_DIR}/process_manager.sh"
    pm_status=$?
    if [ $pm_status -ne 0 ]; then
        exit $pm_status
    fi
    shift
    exec "$@"
fi

# Check if the command exists by looking for its handler
command=$1
handler_function="${command}_handler"

if [[ $(type -t "$handler_function") == function ]]; then
    shift
    "$handler_function" "$@"
else
    log_error "CLI" "Unknown command: $command"
    echo "Run 'worker help' to see available commands."
    exit 1
fi