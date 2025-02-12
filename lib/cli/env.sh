#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Function to display current environment settings or a specific variable
get_environment() {
    if [ $# -eq 0 ]; then
        log_success "Current Environment Settings:" "$(env)"
    else
        log_success "$1" "${!1}"
    fi
}

# Function to set a new environment variable
set_environment() {
    if [ $# -ne 2 ]; then
        log_warn "CLI" "Usage: $0 env set <VARIABLE_NAME> <value>"
        return 1
    fi
    export "$1=$2"
    log_success "CLI" "Set $1 to '$2'."
}

# Handle environment commands
env_handler() {
    case $1 in
        get)
            shift
            get_environment "$@"
            ;;
        set)
            shift
            if [ $# -eq 2 ]; then
                set_environment "$@"
            else
                log_warn "CLI" "Usage: $0 env set <VARIABLE_NAME> <value>"
                exit 1
            fi
            ;;
        *)
            log_warn "CLI" "Usage: $0 env {show [VARIABLE_NAME]|set <VARIABLE_NAME> <value>}"
            exit 1
            ;;
    esac
}