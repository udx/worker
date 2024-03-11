# Utility functions library.
#
# Example usage:
#
# [bash] source "./modules/utils.sh"
# [bash] env_defaults
#

ping_pong() {
    read -p "Ping? " answer
    
    if [[ $answer == "Pong" ]]; then
        echo "Pong received"
    else
        echo "Invalid response: $answer"
    fi
}

load_colors() {
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    RESET=$(tput sgr0)
}

env_defaults() {
    load_colors
    
    # Copy package.json and package-lock.json
    cp /home/app/package*.json ./
    
    # Install application dependencies
    npm install
    
    # Copy the rest of the application
    cp -r /home/app/* ./
}

nice_logs() {
    message=$1
    type=$2
    
    case $type in
        "success")
            echo "${GREEN}${type} ${message}${RESET}"
        ;;
        "info")
            echo "${BLUE}${type} ${message}${RESET}"
        ;;
        "warn")
            echo "${YELLOW}${type} ${message}${RESET}"
        ;;
        "error")
            echo "${RED}${type} ${message}${RESET}"
        ;;
        *)
            echo "${type} ${message}"
        ;;
    esac
}