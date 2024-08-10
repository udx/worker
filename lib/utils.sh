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
        local log_type="$1"
        local log_message="$2"
        
        case $log_type in
            "info")
                echo -e "\033[1;34m[INFO]\033[0m $log_message"
            ;;
            "error")
                echo -e "\033[1;31m[ERROR]\033[0m $log_message"
            ;;
            "success")
                echo -e "\033[1;32m[SUCCESS]\033[0m $log_message"
            ;;
            *)
                echo "$log_message"
            ;;
        esac
    }
    
    # Function to resolve placeholders with environment variables
    resolve_env_vars() {
        local value="$1"
        eval echo "$value"
    }
fi