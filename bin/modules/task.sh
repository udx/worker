#!/bin/bash
#
# This is the task module.
# It is responsible for setting up the environment to perform CI/CD jobs, runbooks, and other operational tasks.
#

source "./utils.sh"

nice_logs "Task module loaded" "success"

# Set the entrypoint to start the application
# exec node index.js
