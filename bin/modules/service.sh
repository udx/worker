#!/bin/bash
#
# This is the service module.
# It is responsible for setting up the environment to run the web application, API or web service in.
# 
#

# Load the utility functions
source "./utils.sh"

nice_logs "Task module loaded" "success"

sleep 1

nice_logs "pm2 package is required, installation..." "info"

sleep 1

# Install pm2
npm install pm2

sleep 1

nice_logs "pm2 package installed successfully." "success"

# Set the entrypoint to start pm2 processes
# exec pm2-runtime start /home/etc/ecosystem.config.js
