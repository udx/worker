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
    read -r answer  
    
    if [ "$answer" = "Pong" ]; then
        echo "Pong received"
    else
        echo "Invalid response: $answer"
    fi
}