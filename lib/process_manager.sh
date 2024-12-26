#!/bin/bash

# Function to check if systemd should be enabled
should_enable_systemd() {
    if [ -f "$CONFIG_FILE" ]; then
        return 0
    else
        return 1
    fi
}

# Function to parse service information from YAML configuration
parse_service_info() {
    local service_yaml="$1"
    name=$(echo "$service_yaml" | jq -r '.name' -)
    exec_start=$(echo "$service_yaml" | jq -r '.exec_start' -)
    after=$(echo "$service_yaml" | jq -r '.after' -)
}

# Function to create a systemd service file from a template
create_service_file() {
    local template_file="$SERVICE_DIR/default.service"
    sed -e "s|\${name}|$name|g" \
    -e "s|\${exec_start}|$exec_start|g" \
    -e "s|\${after}|$after|g" \
    "$template_file" > "${SERVICE_DIR}/${name}.service"
}

# Main function to generate systemd service unit files from template based on services.yml
generate_and_activate_services() {
    if ! should_enable_systemd; then
        echo "Systemd is not enabled. services.yml not found."
        return 1
    fi
    
    echo "services.yml found. Generating and managing systemd service files..."
    
    local services_yaml
    services_yaml=$(yq eval -o=json '.services[]' "$CONFIG_FILE" | jq -c .)

    # Use a temporary file to avoid a subshell
    local services_file
    services_file=$(mktemp)
    echo "$services_yaml" > "$services_file"

    # Read all lines into an array, then delete the file
    mapfile -t services_array < "$services_file"
    rm -f "$services_file"

    # Process each service in the array
    for service_yaml in "${services_array[@]}"; do
        parse_service_info "$service_yaml"
        
        if [[ -n "$name" && -n "$exec_start" && -n "$after" ]]; then
            create_service_file || { echo "Failed to create service file for $name"; return 1; }
            echo "Service file for $name created."
        else
            echo "Missing required service fields for a service in services.yml"
            return 1
        fi
    done
}

# Variables (these should be defined or passed to the script)
CONFIG_FILE="/etc/worker/services.yml"
SERVICE_DIR="/home/${USER}/etc"