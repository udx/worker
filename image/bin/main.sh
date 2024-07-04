#!/bin/bash
set -e

# Function to handle nice logs
nice_logs() {
    local message=$1
    local level=$2
    case $level in
        info)
            echo "[info]: $message"
        ;;
        success)
            echo "[success]: $message"
        ;;
        error)
            echo "[error]: $message"
        ;;
        *)
            echo "$message"
        ;;
    esac
}

# Print the logo with a delay after each character
str=$'
        _|            _   _ |   _  _
__ |_| (_| )( .  \)/ (_) |  |( (- |  __
\n'
for (( i=0; i<${#str}; i++ )); do
  echo -n "${str:$i:1}"
  sleep 0.01
done

sleep 1

# Load all modules in the lib directory
modules_dir="/usr/local/lib"
if [ -d "$modules_dir" ]; then
    for module_file in "$modules_dir"/*.sh; do
        [ -e "$module_file" ] || continue
        source "$module_file"
    done
else
    echo "Directory $modules_dir does not exist."
    exit 1
fi

# Initialize all modules
init_environment
init_auth
init_secrets
init_cleanup

nice_logs "Here you go, welcome to UDX Worker Container." "info"
nice_logs "..."

sleep 1

nice_logs "Init the environment..." "info"
nice_logs "..."

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
