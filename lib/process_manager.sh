#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Define paths
USER_CONFIG_PATH="${HOME}/.config/worker/services.yaml"
BUILT_IN_CONFIG_PATH="${WORKER_CONFIG_DIR}/services.yaml"
CONFIG_FILE=""

# Supervisor configuration paths
COMMON_TEMPLATE_FILE="${WORKER_CONFIG_DIR}/supervisor/common.conf"
PROGRAM_TEMPLATE_FILE="${WORKER_CONFIG_DIR}/supervisor/program.conf"
FINAL_CONFIG="${WORKER_CONFIG_DIR}/supervisor/supervisord.conf"

# Set up signal handling
trap 'handle_supervisor_signals SIGTERM' SIGTERM
trap 'handle_supervisor_signals SIGINT' SIGINT

ensure_process_manager_dependencies() {
    local missing=false

    for command in yq jq; do
        if ! command -v "$command" >/dev/null 2>&1; then
            log_error "Process Manager" "$command is not installed. Please ensure it is available in the PATH."
            missing=true
        fi
    done

    [[ "$missing" == "false" ]]
}

# Main execution
main() {
    local enabled_services_count

    if ! ensure_process_manager_dependencies; then
        exit 1
    fi

    CONFIG_FILE=$(get_service_config_path)

    if [[ -z "$CONFIG_FILE" ]]; then
        log_info "No services configuration found."
        log_info "Run 'worker service' for information about service configuration"
        exit 0
    fi

    if ! enabled_services_count=$(count_enabled_services); then
        exit 1
    fi

    if [[ "${enabled_services_count:-0}" -eq 0 ]]; then
        log_info "No enabled services found in $CONFIG_FILE."
        exit 0
    fi

    log_info "Process Manager" "Starting process manager..."
    
    if ! configure_and_execute_services; then
        log_error "Process Manager" "Failed to configure and start services"
        log_info "Run 'worker service' for information about service configuration"
        exit 1
    fi

    # Wait for services to be ready
    if ! wait_for_services_ready; then
        log_error "Process Manager" "Services failed to start properly"
        exit 1
    fi

    # Monitor services in the background
    monitor_services &
    
    # Wait for signals
    wait
}

get_service_config_path() {
    if [[ -f "$USER_CONFIG_PATH" && -s "$USER_CONFIG_PATH" ]]; then
        echo "$USER_CONFIG_PATH"
        return 0
    fi

    if [[ -f "$BUILT_IN_CONFIG_PATH" && -s "$BUILT_IN_CONFIG_PATH" ]]; then
        echo "$BUILT_IN_CONFIG_PATH"
        return 0
    fi

    return 1
}

count_enabled_services() {
    local enabled_services_count

    if ! enabled_services_count=$(yq e '.services // [] | map(select(.ignore != true)) | length' "$CONFIG_FILE" 2>/dev/null); then
        log_error "Process Manager" "Failed to parse services configuration: $CONFIG_FILE"
        return 1
    fi

    echo "${enabled_services_count:-0}"
}

has_enabled_services() {
    local enabled_services_count

    enabled_services_count=$(count_enabled_services) || return 1

    [[ "${enabled_services_count:-0}" -gt 0 ]]
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

    # Use 'false' as default for 'stopasgroup' if not specified
    stopasgroup=$(echo "$service_json" | jq -r '.stopasgroup // "false"')
    # Use 'false' as default for 'killasgroup' if not specified
    killasgroup=$(echo "$service_json" | jq -r '.killasgroup // "false"')
    
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

    # Set startretries based on autorestart
    local startretries
    if [ "$autorestart" = "true" ]; then
        startretries=3  # Default supervisor behavior
    else
        startretries=0  # Don't retry if autorestart is false
    fi

    # Add an additional newline for better separation and readability
    echo -e "\n" >> "$FINAL_CONFIG"
    
    sed "s|\${process_name}|$name|g; \
        s|\${command}|$command|g; \
        s|\${autostart}|$autostart|g; \
        s|\${autorestart}|$autorestart|g; \
        s|\${startretries}|$startretries|g; \
        s|\${envs}|$envs|g; \
        s|\${stopasgroup}|$stopasgroup|g; \
        s|\${killasgroup}|$killasgroup|g" "$PROGRAM_TEMPLATE_FILE" >> "$FINAL_CONFIG"
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
    
    # Check if supervisor is already running
    if pgrep -f "supervisord" >/dev/null; then
        # Reload configuration
        if supervisorctl reread && supervisorctl update; then
            log_info "Supervisor configuration reloaded"
            return 0
        fi
        log_error "Failed to reload supervisor configuration"
        return 1
    fi
    
    # Start supervisord in daemon mode
    supervisord
    
    # Wait for supervisor to be ready
    local max_attempts=10
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if supervisorctl status >/dev/null 2>&1; then
            log_info "Supervisor is ready"
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    
    log_error "Failed to start supervisord"
    return 1
}

# Function to check for service configurations
should_generate_config() {
    if [[ -z "$CONFIG_FILE" ]]; then
        CONFIG_FILE=$(get_service_config_path)
    fi

    if [ -f "$CONFIG_FILE" ] && has_enabled_services; then
        return 0
    else
        return 1
    fi
}

# Function to configure services
configure_services() {
    if [[ -z "$CONFIG_FILE" ]]; then
        CONFIG_FILE=$(get_service_config_path)
    fi

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

# Only run main if not in service mode
if [ -z "$WORKER_SERVICE_MODE" ]; then
    main
fi
