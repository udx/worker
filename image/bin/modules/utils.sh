#!/bin/sh

# Utility functions library.
#
# Example usage:
#
# [sh] . "./modules/utils.sh"
# [sh] env_defaults
#

ping_pong() {
    echo "Ping? \c"
    read answer
    
    if [ "$answer" = "Pong" ]; then
        echo "Pong received"
    else
        echo "Invalid response: $answer"
    fi
}

nice_logs() {
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    GREY=$(tput setaf 8)
    RESET=$(tput sgr0)
    
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
