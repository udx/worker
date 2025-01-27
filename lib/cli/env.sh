#!/bin/bash

# Function to display current environment settings or a specific variable
show_environment() {
    if [ $# -eq 0 ]; then
        echo "Current Environment Settings:"
        env
    else
        echo "$1=${!1}"
    fi
}

# Function to set a new environment variable
set_environment() {
    if [ $# -ne 2 ]; then
        echo "Usage: $0 env set <VARIABLE_NAME> <value>"
        return 1
    fi
    export "$1=$2"
    echo "Set $1 to '$2'."
}

# Handle environment commands
env_handler() {
    case $1 in
        show)
            shift
            show_environment "$@"
            ;;
        set)
            shift
            if [ $# -eq 2 ]; then
                set_environment "$@"
            else
                echo "Usage: $0 env set <VARIABLE_NAME> <value>"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 env {show [VARIABLE_NAME]|set <VARIABLE_NAME> <value>}"
            exit 1
            ;;
    esac
}