#!/bin/bash

# Prevent the script from being sourced multiple times
if [ -z "${UTILS_SH_INCLUDED+x}" ]; then
    UTILS_SH_INCLUDED=true
    
    # Function to print the UDX logo
    udx_logo() {
        cat /home/"${USER}"/etc/logo.txt
    }

    # Simple logging functions
    log_info() {
        echo "[INFO] $1"
    }

    log_error() {
        echo "[ERROR] $1"
    }    
    
    # Function to resolve placeholders with environment variables
    resolve_env_vars() {
        local value="$1"
        eval echo "$value"
    }
fi
