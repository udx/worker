#!/bin/bash

source bin/modules/utils.sh

loading_icon 2 "..."

############
#          #
# Commands #
#          #
############

# Use the functions in the script
message "white" "\n\nWhat I can do:\n---\n"

loading_icon 1 "..."

# Parse the commands from package.json using jq
global_package_path=$(npm root -g)/udx-worker
commands=$(jq -r '.config.commands[] | "\(.name)=\(.description)"' $global_package_path/package.json)

declare -A commands_map
while IFS="=" read -r key value; do
  commands_map["$key"]="$value"
done <<< "$commands"

for command in "${!commands_map[@]}"; do
  message "success" "${commands_map[$command]}:"
  sleep 0.05
  message "success" "  udx-worker ${command}\n"
  sleep 0.1
done