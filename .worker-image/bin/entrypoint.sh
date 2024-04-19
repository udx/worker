#!/bin/bash

# Load all modules in the modules directory
for module_file in /home/bin/modules/*.sh; do
    if [ -f "$module_file" ]; then
        source "$module_file"
    fi
done

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker." "info"

nice_logs "..."

sleep 3

nice_logs "[Starting the environment modules." "info"

# Authorize environment actor
ActorsAuth

# Fetch environment secrets
FetchSecrets

# Clean up actors
CleanUpActors

# Fetch environment variables
FetchEnvironmentVariables

nice_logs "..."

sleep 3

nice_logs "The worker has started successfully." "success"

# Check if the command is "project_init"
if [ "$1" = "project_init" ]; then
    # Initialize the project
    InitProject
fi