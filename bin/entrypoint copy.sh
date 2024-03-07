# Define some colors using tput
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Use the colors in logs
echo "${GREEN}Here you go, welcome to docker builder tool.${RESET}"
echo "..."

sleep 3

echo "${YELLOW}Build and deploy ephemeral tooling worker.${RESET}"
echo "..."

sleep 3

# echo "${RED}This is an error message.${RESET}"

# Ask the user what mode to run in
echo "${YELLOW}Please choose mode? (CLI/ENVIRONMENT/CHAT)${RESET}"
read -r mode
mode=${mode:-cli}
mode=$(echo "$mode" | tr '[:lower:]' '[:upper:]')

# if [[ "$mode" == *"CLI"* ]]; then
#     echo "${GREEN}Starting CLI mode...${RESET}"
#     # docker-compose run -d --build --force-recreate app bash -c "$command"
#     elif [[ "$mode" == *"ENVIRONMENT"* ]]; then
#     echo "${GREEN}Starting Environment mode...${RESET}"
#     echo "${YELLOW}It's in development yet...${RESET}"
#     exit;
# else
#     echo "${GREEN}Starting Chat mode...${RESET}"
#     echo "${YELLOW}It's in development yet...${RESET}"
#     exit;
# fi

# if docker ps | grep -q "app"; then
#     echo "${GREEN}$mode mode is already enabled.${RESET}"
    
# else
#     docker-compose up $mode --build -d --force-recreate > /dev/null 2>&1
# fi

sleep 1

echo "..."

sleep 3

echo "${GREEN}$mode mode has started successfully.${RESET}"

cd src/app/

echo "${YELLOW}Installing dependencies.${RESET}"

# npm install > /dev/null 2>&1
npm install --silent --quiet --no-progress --no-audit > /dev/null 2>&1

node index.js "$@"