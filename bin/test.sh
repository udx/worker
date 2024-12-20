#!/bin/bash

echo "Starting validation tests..."

# Function to test if a command is available and show its version
check_command() {
    local cmd_path
    cmd_path=$(command -v "$1")
    if [ -x "$cmd_path" ]; then
        echo "[INFO] $1 is installed at $cmd_path."
        local version
        version=$($1 --version 2>&1 | head -n 1)
        echo "[INFO] $1 version: $version"
    else
        echo "[ERROR] $1 is not installed or not in PATH."
        exit 1
    fi
}

# Verify gcloud, aws, az, and bw commands are available
check_command gcloud
check_command aws
check_command az
check_command bw

echo "All validation tests passed successfully."