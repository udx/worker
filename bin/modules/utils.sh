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
    GREY=$(tput setaf 8)
    RESET=$(tput sgr0)
}

env_defaults() {
    
    env_type=$1
    
    nice_logs "Loading environment ${env_type} defaults..." "info"
    
    load_colors
}

nice_logs() {
    message=$1
    type=$2
    
    case $type in
        "success")
            echo "${GREEN} ${message}${RESET}"
        ;;
        "info")
            echo "${BLUE} ${message}${RESET}"
        ;;
        "warn")
            echo "${YELLOW} ${message}${RESET}"
        ;;
        "error")
            echo "${RED} ${message}${RESET}"
        ;;
        *)
            echo "${type} ${message}"
        ;;
    esac
}