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
modules_dir="/home/$USER/bin-modules/modules"
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

# Execute the provided command if any, else proceed with the script
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    # Use the colors in logs
    nice_logs "Here you go, welcome to UDX Worker Container." "info"
    nice_logs "..."

    sleep 1

    nice_logs "Init the environment..." "info"
    nice_logs "..."

    # Call the EnvironmentController from the modules environment
    nice_logs "Do the configuration..." "info"

    # Calling the main function from environment.sh
    configure_environment

    nice_logs "..."
    sleep 1

    nice_logs "The worker has started successfully." "success"
fi
