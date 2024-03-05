#!/bin/bash
# cli.sh

# Define your common logic here
# Call the Node.js CLI script with the passed arguments

echo "${GREEN}Call the Node.js CLI script with the passed arguments${RESET}"

node index.js "$@"

sleep infinity

# ls -la
