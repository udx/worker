#!/bin/bash

# Define paths
CONFIG_FILE="/etc/worker/services.yml"
COMMON_TEMPLATE_FILE="/home/${USER}/etc/supervisor.common.conf"
PROGRAM_TEMPLATE_FILE="/home/${USER}/etc/supervisor.program.conf"
FINAL_CONFIG="/home/${USER}/etc/supervisord.conf"

# Function to check for service configurations
should_generate_config() {
    local enabled_services_count
    # Extract enabled services into JSON format
    services_yaml=$(yq e -o=json '.services[] | select(.enabled == true)' "$CONFIG_FILE")
    # Count the number of items in the JSON array, trimming any newlines or spaces
    enabled_services_count=$(echo "$services_yaml" | jq -c '. | length' | tr -d '\n')

    # Check if the configuration file exists and there is at least one enabled service
    if [ -f "$CONFIG_FILE" ] && [ "${enabled_services_count:-0}" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Helper function to parse and process each service configuration
parse_service_info() {
    local service_json="$1"
    local name command autostart autorestart environment
    
    name=$(echo "$service_json" | jq -r '.name')
    command=$(echo "$service_json" | jq -r '.command')
    autostart=$(echo "$service_json" | jq -r '.autostart // "false"')
    autorestart=$(echo "$service_json" | jq -r '.autorestart // "false"')
    environment=$(echo "$service_json" | jq -r '.environment // [] | join(",")')
    
    # Add an additional newline for better separation and readability
    echo -e "\n" >> "$FINAL_CONFIG"  # Adds two newlines to the end of the file
    
    sed "s|\${process_name}|$name|g; \
        s|\${command}|$command|g; \
        s|\${autostart}|$autostart|g; \
        s|\${autorestart}|$autorestart|g; \
        s|\${envs}|$environment|g" "$PROGRAM_TEMPLATE_FILE" >> "$FINAL_CONFIG"
}

# Function to start Supervisor with the generated configuration
start_supervisor() {
    echo "Starting Supervisor with the generated configuration..."
    supervisord -c "$FINAL_CONFIG"
}

# Function to configure and start the Supervisor
configure_and_execute_services() {
    if ! should_generate_config; then
        echo "No services found in $CONFIG_FILE. No Supervisor configuration generated."
        return 1
    fi
    
    # Copy the base Supervisor common configuration only once at the start.
    cp "$COMMON_TEMPLATE_FILE" "$FINAL_CONFIG"
    
    # Convert enabled services to JSON and process each.
    local services_yaml
    services_yaml=$(yq e -o=json '.services[] | select(.enabled == true)' "$CONFIG_FILE" | jq -c .)
    
    if [ -z "$services_yaml" ]; then
        echo "Failed to parse services from $CONFIG_FILE or no services defined."
        return 1
    fi
    
    echo "$services_yaml" | while read -r service_json; do
        parse_service_info "$service_json"
    done
    
    # After generating the config and processing services, start Supervisor
    start_supervisor
}