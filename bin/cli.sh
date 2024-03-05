#!/bin/bash
# cli.sh

# Define your common logic here
# Call the Node.js CLI script with the passed arguments

echo "${GREEN}Call the Node.js CLI script with the passed arguments${RESET}"

if [ $TYPE == "cli" ]; then
    echo "cli"
    node index.js "$@"
else
    echo "env"
    # node ./src/app/index.js "$@"
    node ./test/index.js "$@"
fi

sleep infinity

# ls -la
