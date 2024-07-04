#!/bin/sh

# Utility functions library.
#
# Example usage:
#
# [sh] . "/usr/local/lib/utils.sh"
# [sh] env_defaults
#

# Function to simulate a ping-pong interaction
ping_pong() {
    echo "Ping? \c"
    read -r answer  
    
    if [ "$answer" = "Pong" ]; then
        echo "Pong received"
    else
        echo "Invalid response: $answer"
    fi
}

# Function to resolve placeholders with environment variables
resolve_env_vars() {
    local value="$1"
    eval echo "$value"
}

# Function to redact passwords in the logs
redact_password() {
    echo "$1" | sed -E 's/("password":\s*")[^"]+/\1*********/g'
}

# Function to redact sensitive URLs
redact_sensitive_urls() {
    echo "$1" | sed -E 's/(https:\/\/[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\.([A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)([A-Za-z0-9\/_-]*)/\1.*********\2.*********\3/g'
}

# Function to load a file with exported environment variables
load_env_file() {
    local file_path="$1"
    
    if [ -f "$file_path" ]; then
        set -a
        . "$file_path"
        set +a
        echo "Environment variables loaded from $file_path"
    else
        echo "Environment file $file_path not found"
    fi
}

# Function to write environment variables to a file
write_env_file() {
    local file_path="$1"
    shift
    local vars="$@"

    echo "# Environment variables" > "$file_path"
    for var in $vars; do
        echo "export $var=\"${!var}\"" >> "$file_path"
    done
    echo "Environment variables written to $file_path"
}
