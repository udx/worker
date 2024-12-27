#!/bin/bash

# Define paths
CONFIG_FILE="/etc/worker/services.yml"
TEMPLATE_FILE="/home/${USER}/etc/supervisor.default"
FINAL_CONFIG="/home/${USER}/etc/supervisord.conf"

# Function to check for service configurations
should_generate_config() {
    if [ -f "$CONFIG_FILE" ] && [ "$(yq e '.services | length' "$CONFIG_FILE")" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Helper function to parse and process each service configuration
parse_service_info() {
    local service_json="$1"
    local name=$(echo "$service_json" | jq -r '.name')
    local command=$(echo "$service_json" | jq -r '.command')
    local autostart=$(echo "$service_json" | jq -r '.autostart // "false"')
    local autorestart=$(echo "$service_json" | jq -r '.autorestart // "false"')
    local stderr_logfile=$(echo "$service_json" | jq -r '.stderr_logfile // ""')
    local stdout_logfile=$(echo "$service_json" | jq -r '.stdout_logfile // ""')
    local environment=$(echo "$service_json" | jq -r '.environment // [] | join(",")')
    
    # For each service, replace placeholders and append to FINAL_CONFIG
    sed "s|\${process_name}|$name|g; \
        s|\${command}|$command|g; \
        s|\${autostart}|$autostart|g; \
        s|\${autorestart}|$autorestart|g; \
        s|\${stderr_logfile}|$stderr_logfile|g; \
        s|\${stdout_logfile}|$stdout_logfile|g; \
        s|\${envs}|$environment|g" "$TEMPLATE_FILE" >> "$FINAL_CONFIG"
}

# Function to start Supervisor with the generated configuration
start_supervisor() {
    echo "Starting Supervisor with the generated configuration..."
    supervisord -c "$FINAL_CONFIG"
}

# Function to configure and start the Supervisor
configure_and_execute_services() {
    if ! should_generate_config; then
        echo "No services found in $CONFIG_FILE. Skipping Supervisor configuration."
        return 1
    fi
    
    # Copy the base Supervisor configuration.
    cp "$TEMPLATE_FILE" "$FINAL_CONFIG"
    
    # Remove the template [program:x] section from FINAL_CONFIG
    sed -i '/\[program:\${process_name}\]/,/^$/d' "$FINAL_CONFIG"
    
    # Convert services to JSON and process each.
    local services_yaml
    services_yaml=$(yq e -o=json '.services[]' "$CONFIG_FILE" | jq -c .)
    
    if [ -z "$services_yaml" ]; then
        echo "Failed to parse services from $CONFIG_FILE or no services defined."
        return 1
    fi
    
    # Use a temporary file to avoid subshell issues
    local services_file
    services_file=$(mktemp)
    
    echo "$services_yaml" > "$services_file"
    mapfile -t services_array < "$services_file"
    rm -f "$services_file"
    
    # Process each service in the array
    for service_json in "${services_array[@]}"; do
        parse_service_info "$service_json"
    done
    
    # After generating the config and processing services, start Supervisor
    start_supervisor
}