function loading_icon() {
    local load_interval="${1}"
    local loading_message="${2}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )

    message "success" $loading_message

    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT
    while [ "${load_interval}" -ne "${elapsed}" ]; do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            message "success" ...
            sleep 0.25
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b\n"
}

declare -A colors
colors[error]='\033[0;31m'
colors[warning]='\033[1;33m'
colors[info]='\033[0;36m'
colors[success]='\033[0;32m'
colors[white]='\033[1;37m'
NC='\033[0m' # No Color

# Define a single function for all message types
message() {
  local type=$1
  local text=$2
  local arg=${3:-""}
  if [ "$arg" = "-n" ]; then
    printf "${colors[$type]}%s${NC}" "$text"
  else
    echo -e "${colors[$type]}$text${NC}"
  fi
}

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

declare -A commands
commands=(
  ["exec"]="This command executes a command in the context of the udx-worker"
  ["configure"]="This command configure new tooling worker based on udx-worker"
  ["integrate"]="This command generates CI implemetation utilizing udx-worker tooling worker"
  ["build"]="This command detects type of project and build it"
  ["test"]="This command detects type of project and run tests against it"
  ["deploy"]="This command detects type of project and deploy it"
  ["chat"]="This command starts AI chat bot with internal knowledgebase"
  ["help"]="Show this help message"
)

for command in "${!commands[@]}"; do
  message "info" "${commands[$command]}:"
  sleep 0.05
  message "info" "  udx-worker ${command}\n"
  sleep 0.1
done