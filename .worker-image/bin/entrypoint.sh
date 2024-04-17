#!/bin/bash

# Load all modules in the modules directory
for module_file in /home/bin/modules/*.sh; do
    if [ -f "$module_file" ]; then
        source "$module_file"
    fi
done

# Authorize environment actor
ActorsAuth

# Fetch environment secrets
FetchSecrets

CleanUpActors() {
    # Clean up the environment
    echo "Cleaning up the environment..."
}

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker." "info"

nice_logs "..."

sleep 3

nice_logs "[Starting the environment modules." "info"

nice_logs "..."

sleep 3

nice_logs "The worker has started successfully." "success"