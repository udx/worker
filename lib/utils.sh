#!/bin/bash

# Prevent the script from being sourced multiple times
if [ -z "${UTILS_SH_INCLUDED+x}" ]; then
    UTILS_SH_INCLUDED=true
    
    # Function to print the UDX logo
    udx_logo() {
        cat /home/"${USER}"/etc/logo.txt
    }
    
    # Function to print nice logs with colors
    nice_logs() {
        local log_message="$1 $2"

        echo "$log_message"
    }
    
    # Function to resolve placeholders with environment variables
    resolve_env_vars() {
        local value="$1"
        eval echo "$value"
    }
fi
