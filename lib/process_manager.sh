#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Define paths
DEFAULT_CONFIG_FILE="/home/udx/services.yaml"
CONFIG_FILE="${USER_CONFIG_PATH:-$DEFAULT_CONFIG_FILE}"
COMMON_TEMPLATE_FILE="/usr/local/configs/supervisor/common.conf"
PROGRAM_TEMPLATE_FILE="/usr/local/configs/supervisor/program.conf"
FINAL_CONFIG="/usr/local/configs/supervisor/supervisord.conf"

# Copy common configuration
cp "$COMMON_TEMPLATE_FILE" "$FINAL_CONFIG"

# Process services if config exists
if [ -f "$CONFIG_FILE" ]; then
    services_json=$(yq e -o=json '.services' "$CONFIG_FILE")
    
    # Process each service
    echo "$services_json" | jq -c '.[]' | while read -r service; do
        name=$(echo "$service" | jq -r '.name')
        command=$(echo "$service" | jq -r '.command')
        ignore=$(echo "$service" | jq -r '.ignore // "false"')
        autostart=$(echo "$service" | jq -r '.autostart // "true"')
        autorestart=$(echo "$service" | jq -r '.autorestart // "false"')
        envs=$(echo "$service" | jq -r '.envs // [] | join(",")')
        
        if [[ "$ignore" != "true" ]] && [ -n "$name" ] && [ -n "$command" ]; then
            echo -e "\n" >> "$FINAL_CONFIG"
            sed "s|\${process_name}|$name|g; \
                s|\${command}|$command|g; \
                s|\${autostart}|$autostart|g; \
                s|\${autorestart}|$autorestart|g; \
                s|\${envs}|$envs|g" "$PROGRAM_TEMPLATE_FILE" >> "$FINAL_CONFIG"
        fi
    done
fi

# Start supervisord
exec /usr/bin/supervisord -c "$FINAL_CONFIG"

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
        log_error "Process Manager" "Error: 'name' not set for service $name. Skipping..."
        return
    fi
    
    # Check if 'command' is set, log error and return if not
    if [ -z "$command" ]; then
        log_error "Process Manager" "Error: 'command' not set for service $name. Skipping..."
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

# Function to check if services are active
check_services_status() {
    local service_count
    service_count=$(supervisorctl status | grep -c "RUNNING")
    if [ "$service_count" -gt 0 ]; then
        return 0
    fi
    return 1
}

# Function to wait for services to be ready
wait_for_services_ready() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if check_services_status; then
            log_info "All services are running"
            return 0
        fi
        log_info "Waiting for services to start (attempt $attempt/$max_attempts)..."
        sleep 1
        attempt=$((attempt + 1))
    done
    
    log_error "ProcessManager" "Services failed to start within timeout"
    return 1
}

# Function to monitor services and keep container running
monitor_services() {
    while true; do
        if ! check_services_status; then
            log_error "ProcessManager" "No active services found, exiting..."
            exit 1
        fi
        sleep 5
    done
}

# Function to handle graceful shutdown
handle_supervisor_signals() {
    local signal=$1
    log_info "$signal received, stopping all services..."

    # First stop each service gracefully
    for program in $(supervisorctl status | awk '{print $1}'); do
        log_info "Gracefully stopping $program..."
        supervisorctl stop "$program"
        
        # Give the service time to handle its shutdown
        local timeout=10
        local elapsed=0
        while [ $elapsed -lt $timeout ]; do
            if ! supervisorctl status "$program" | grep -q "RUNNING\|STOPPING"; then
                log_info "$program stopped successfully"
                break
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
    done

    # Finally stop supervisor itself
    log_info "All services stopped, shutting down supervisor..."
    supervisorctl shutdown
    exit 0
}

# Function to start Supervisor with the generated configuration
start_supervisor() {
    log_info "Starting supervisord..."
    
    # Start supervisord in non-daemon mode
    exec supervisord -n
}

# Function to configure services
configure_services() {
    if ! should_generate_config; then
        log_warn "Process Manager" "No services found in $CONFIG_FILE. No Supervisor configuration generated."
        return 1
    fi
    
    # Copy the base Supervisor common configuration only once at the start.
    cp "$COMMON_TEMPLATE_FILE" "$FINAL_CONFIG"
    
    # Convert enabled services to JSON and process each.
    local services_yaml
    services_yaml=$(yq e -o=json '.services[] | select(.ignore != true)' "$CONFIG_FILE" | jq -c .)
    
    if [ -z "$services_yaml" ]; then
        log_error "Process Manager" "Failed to parse services from $CONFIG_FILE or no services defined."
        return 1
    fi
    
    echo "$services_yaml" | while read -r service_json; do
        parse_service_info "$service_json"
    done
    
    log_info "Service configuration generated successfully."
    return 0
}

# Function to configure and start services
configure_and_execute_services() {
    # First configure the services
    if ! configure_services; then
        return 1
    fi
    
    # Then start supervisor
    start_supervisor
}