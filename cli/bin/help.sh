source cli/bin/modules/utils.sh

loading_icon 1 "Loading..."

########
#      #
# Logo #
#      #
########

# Define the logo string
str=$'
        _|            _   _ |   _  _ 
__ |_| (_| )( .  \)/ (_) |  |( (- |  __
\n'

# Print the logo with a delay after each character
for (( i=0; i<${#str}; i++ )); do
  message "success" "${str:$i:1}" "-n"
  # Add a pause only if the current character is not a space or newline
  if [[ "${str:$i:1}" != " " && "${str:$i:1}" != $'\n' ]]; then
    sleep 0.01
  fi
done

sleep 1

# Use the functions in the script
message "white" "\n\nWhat I can do:\n---\n"

sleep 0.5

# Parse the commands from package.json using jq
commands=$(jq -r '.config.commands[] | "\(.name)=\(.description)"' cli/package.json)

declare -A commands_map
while IFS="=" read -r key value; do
  commands_map["$key"]="$value"
done <<< "$commands"

for command in "${!commands_map[@]}"; do
  message "info" "${commands_map[$command]}:"
  sleep 0.05
  message "info" "  udx-worker ${command}\n"
  sleep 0.1
done