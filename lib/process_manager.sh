#!/bin/bash

# Define paths
DEFAULT_CONFIG_FILE="/usr/local/configs/worker/services.yml"
# Define the user-specific configuration path search
USER_CONFIG_PATH=$(find "/home/$USER" -name 'services.yaml' -print -quit)

# Use the first user-specific config found; if none, use the default
CONFIG_FILE="${USER_CONFIG_PATH:-$DEFAULT_CONFIG_FILE}"
COMMON_TEMPLATE_FILE="/usr/local/configs/supervisor/common.conf"
PROGRAM_TEMPLATE_FILE="/usr/local/configs/supervisor/program.conf"
FINAL_CONFIG="/usr/local/configs/supervisor/supervisord.conf"

# Function to check for service configurations
should_generate_config() {
    local enabled_services_count
    # Extract services into JSON format
    services_yaml=$(yq e -o=json '.services[] | select(.ignore != true)' "$CONFIG_FILE")
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
    local name command autostart autorestart envs
    
    name=$(echo "$service_json" | jq -r '.name')
    command=$(echo "$service_json" | jq -r '.command')
    # Ensure 'ignore' is considered. If not present, default to "false"
    ignore=$(echo "$service_json" | jq -r '.ignore // "false"')
    # Use 'true' as default for 'autostart' if not specified
    autostart=$(echo "$service_json" | jq -r '.autostart // "true"')
    # Use 'false' as default for 'autorestart' if not specified
    autorestart=$(echo "$service_json" | jq -r '.autorestart // "false"')
    # Ensure 'envs' defaults to an empty array if not specified
    envs=$(echo "$service_json" | jq -r '.envs // [] | join(",")')
    
    # Ignore the service if 'ignore' is set to "true"
    if [[ "$ignore" == "true" ]]; then
        return
    fi
    
    # Check if 'name' is set, log error and return if not
    if [ -z "$name" ]; then
        echo "Error: 'name' not set for a service. Skipping..."
        return
    fi
    
    # Check if 'command' is set, log error and return if not
    if [ -z "$command" ]; then
        echo "Error: 'command' not set for service $name. Skipping..."
        return
    fi

    # Add an additional newline for better separation and readability
    echo -e "\n" >> "$FINAL_CONFIG"
    
    sed "s|\${process_name}|$name|g; \
        s|\${command}|$command|g; \
        s|\${autostart}|$autostart|g; \
        s|\${autorestart}|$autorestart|g; \
        s|\${envs}|$envs|g" "$PROGRAM_TEMPLATE_FILE" >> "$FINAL_CONFIG"
}

# Function to start Supervisor with the generated configuration
start_supervisor() {
    echo "Starting Supervisor with the generated configuration..."
    supervisord
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
    services_yaml=$(yq e -o=json '.services[] | select(.ignore != true)' "$CONFIG_FILE" | jq -c .)
    
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