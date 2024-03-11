#!/bin/bash
#
# This is the service module.
# It is responsible for setting up the environment to run the web application, API or web service in.
#
#

# Load the utility functions
source "/home/bin/modules/utils.sh"

nice_logs "Service module loaded" "success"

sleep 1

# Install
if [ -f "package.json" ]; then
    npm install
    
    sleep 1
    
    nice_logs ""
    
    nice_logs "NPM packages are installed successfully." "success"
    
else
    nice_logs "package.json not found." "error"
    
    sleep 1
    
    nice_logs "Exiting..." "error"
    
    exit 1
fi

sleep 1

nice_logs ""
