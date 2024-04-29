#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status.

# Check if pip and python3 are installed
if ! command -v pip &> /dev/null || ! command -v python3 &> /dev/null
then
    echo "pip and python3 are required but not installed. Please install them and try again."
    exit
fi

# Load all modules in the modules directory
if [ -d "bin-modules/modules" ]; then
    for module_file in bin-modules/modules/*.sh; do
        if [ -f "$module_file" ]; then
            source "$module_file"
        fi
    done
else
    echo "Directory bin-modules/modules does not exist."
    exit
fi

# Use the colors in logs
nice_logs "Here you go, welcome to UDX Worker Container." "info"

nice_logs "..."

sleep 1

nice_logs "Init the environment..." "info"

nice_logs "..."

# Add the current directory to the Python path
export PYTHONPATH="${PYTHONPATH}:$(dirname "$0")"

pip install colorama > /dev/null

# Call the EnvironmentController from the modules environment
python3 -u -c "
import logging
import sys
from modules import environment

logging.basicConfig(level=logging.INFO, stream=sys.stdout, format='\033[1;32m [Environment] %(message)s\033[0m')

logging.info('\033[1;32mDo the configuration...\033[0m')

try:
    environment.EnvironmentController()
except Exception as e:
    logging.exception('An error occurred: ')
"

nice_logs "..."

sleep 1

nice_logs "The worker has started successfully." "success"

# Check if the first argument is "project_init"
if [ "$1" = "project_init" ]; then
    python3 -c 'from modules import project; init_project("apply", True, "$2", "$3")'
fi