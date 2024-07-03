#!/bin/bash
set -e

# Function to handle nice logs
nice_logs() {
    local message=$1
    local level=$2
    case $level in
        info)
            echo "INFO: $message"
            ;;
        success)
            echo "SUCCESS: $message"
            ;;
        error)
            echo "ERROR: $message"
            ;;
        *)
            echo "$message"
            ;;
    esac
}

# Define a single function for all message types
message() {
    local type=$1
    local text=$2
    local arg=${3:-""}
    if [ "$arg" = "-n" ]; then
        printf "%s" "$text"
    else
        echo "$text"
    fi
}

# Logo string
str=$'
        _|            _   _ |   _  _ 
__ |_| (_| )( .  \)/ (_) |  |( (- |  __
\n'

# Print the logo with a delay after each character
for (( i=0; i<${#str}; i++ )); do
  message "success" "${str:$i:1}" "-n"
  # Add a pause only if the current character is not a space or newline
  if [[ "${str:$i:1}" != " " && "${str:$i:1}" != $'\n' ]]; then
    sleep 0.01
  fi
done

sleep 1

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

# Use the logs
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
