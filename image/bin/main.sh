#!/bin/bash
set -e

# Function to handle nice logs
nice_logs() {
    local message=$1
    local level=$2
    case $level in
        info)
            echo -e "\033[32m$message\033[0m"
        ;;
        success)
            echo -e "\033[34m$message\033[0m"
        ;;
        error)
            echo -e "\033[31m$message\033[0m"
        ;;
        *)
            echo "$message"
        ;;
    esac
}

# Load all modules in the modules directory
modules_dir="/usr/local/bin/modules"
if [ -d "$modules_dir" ]; then
    # shellcheck disable=SC1090
    for module_file in "$modules_dir"/*.sh; do
        [ -e "$module_file" ] || continue
        . "$module_file"
    done
else
    echo "Directory $modules_dir does not exist."
    exit 1
fi

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker Container." "info"
nice_logs "..."

sleep 1

nice_logs "Init the environment..." "info"
nice_logs "..."

# Call the EnvironmentController from the modules environment
nice_logs "Do the configuration..." "info"

# Call the main function to configure environment
configure_environment

nice_logs "..."
sleep 1

nice_logs "The worker has started successfully." "success"

# Execute passed commands or default command
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec sh -c "echo NodeJS@$(node -v)"
fi
