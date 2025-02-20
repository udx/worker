#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Constants
SERVICES_CONFIG_DIR="${HOME}/.config/worker"
SERVICES_CONFIG_FILE="${SERVICES_CONFIG_DIR}/services.yaml"

# Show help for service command
service_help() {
    cat << 'EOF'
Usage: worker service <command> [options]

Commands:
  list              List all configured and running services
  status <name>     Show detailed status of a service
  start <name>      Start a service
  stop <name>       Stop a service
  restart <name>    Restart a service
  logs <name>       View service logs
  errors <name>     View service error logs
  config           Show current service configuration
  init             Initialize a new service configuration
  help             Show this help message

Options:
  --format json     Output in JSON format (for list, status, config)
  --tail N         Show last N lines of logs (default: 100)
  --follow         Follow log output in real time
  --error-only     Show only error logs

Examples:
  worker service list
  worker service start my-app
  worker service logs my-app --tail 50 --follow
  worker service status my-app --format json
EOF
}

service_handler() {
    local cmd=$1
    shift  # Remove the command from args

    # Parse format option if present
    local format=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format)
                format="$2"
                shift 2
                ;;
            --format=*)
                format="${1#*=}"
                shift
                ;;
            *)
                break
                ;;
        esac
    done

    # Show help if no command or help requested
    if [ -z "$cmd" ] || [ "$cmd" = "help" ]; then
        service_help
        return 0
    fi

    # Check if services config exists before most commands
    if [ "$cmd" != "init" ]; then
        if [ ! -f "$SERVICES_CONFIG_FILE" ]; then
            log_warn "Service" "No services configuration found"
            log_info "Service" "Run 'worker help service' for information about service configuration"
            return 1
        fi
    fi

    case $cmd in
        list)
            list_services "$format"
            ;;
        status)
            check_status "$1" "$format"
            ;;
        logs)
            follow_logs "$@"
            ;;
        errors)
            follow_logs "$1" "err"
            ;;
        config)
            service_show_config "$format"
            ;;
        init)
            init_service_config
            ;;
        start|stop|restart)
            manage_service "$cmd" "$1"
            ;;
        *)
            log_error "Service" "Unknown command: $cmd"
            service_help
            return 1
            ;;
    esac
}

# Description: List all configured services and their status
# Example: worker service list [--format json]
list_services() {
    local format="$1"
    
    # Check if services config exists
    if [ ! -f "$SERVICES_CONFIG_FILE" ]; then
        if [ "$format" = "json" ]; then
            echo '{"error":"No services configuration found","services":[]}'
        else
            log_warn "Service" "No services configuration found"
            log_info "Service" "Run 'worker service init' to create a new configuration"
        fi
        return 1
    fi

    # Get supervisor status and running services
    local supervisor_status
    local supervisor_running=false
    if supervisor_status=$(supervisorctl status 2>&1); then
        supervisor_running=true
    fi

    # Format and display services
    if [ "$format" = "json" ]; then
        # Build JSON output
        local json_services="[]"
        
        # Add running services if supervisor is running
        if [ "$supervisor_running" = true ] && [ -n "$supervisor_status" ]; then
            json_services="["
            local first=true
            while IFS= read -r line; do
                if [ -n "$line" ]; then
                    if [ "$first" = true ]; then
                        first=false
                    else
                        json_services+=","
                    fi
                    # Parse supervisor status line
                    local name status pid uptime
                    read -r name status pid uptime <<< "$line"
                    json_services+="{\"name\":\"$name\",\"status\":\"$status\",\"pid\":\"$pid\",\"uptime\":\"$uptime\"}"
                fi
            done <<< "$supervisor_status"
            json_services+="]"
        fi
        echo "{\"services\":$json_services}"
    else
        # Show running services if supervisor is running
        if [ "$supervisor_running" = true ]; then
            if [ -n "$supervisor_status" ]; then
                log_info "Service" "Running services:"
                # Print table header
                printf "%-2s %-15s %-8s %-6s %-12s\n" "" "NAME" "STATUS" "PID" "UPTIME"
                printf "%-2s %-15s %-8s %-6s %-12s\n" "" "----" "------" "---" "------"
                while IFS= read -r line; do
                    if [ -n "$line" ]; then
                        # Parse supervisor status line
                        local name status pid uptime
                        read -r name status pid uptime <<< "$line"
                        
                        # Use different symbols based on status
                        local symbol="⚠️"
                        case "$status" in
                            RUNNING) symbol="✅";;
                            STOPPED) symbol="⛔";;
                            FATAL)   symbol="💀";;
                            *)       symbol="⚠️";;
                        esac
                        printf "%-2s %-15s %-8s %-6s %-12s\n" "$symbol" "$name" "$status" "$pid" "$uptime"
                    fi
                done <<< "$supervisor_status"
            else
                log_info "Service" "No running services"
            fi
        else
            log_info "Service" "Supervisor is not running"
            log_info "Service" "Use 'worker service start <name>' to start a service"
        fi
        log_info "Service" "Use 'worker service config' to view service configuration"
    fi
}

# Description: Show detailed status of a specific service
# Example: worker service status my-app [--format json]
check_status() {
    local service=$1
    local format=$2

    # Check if service name is provided
    if [ -z "$service" ]; then
        log_error "Service" "Service name required"
        log_info "Service" "Usage: worker service status <service-name>"
        return 1
    fi

    # Check if service exists in config
    if ! yq e ".services[] | select(.name == \"$service\") | .name" "$SERVICES_CONFIG_FILE" 2>/dev/null | grep -q "$service"; then
        log_error "Service" "Service '$service' not found in configuration"
        return 1
    fi

    # Get service status from supervisor
    local status_output
    status_output=$(supervisorctl status "$service" 2>&1)
    
    # Check if supervisor is running
    if echo "$status_output" | grep -q "unix:///var/run/supervisor.sock no such file"; then
        log_error "Service" "Supervisor is not running"
        log_info "Service" "Use 'worker service start $service' to start the service"
        return 1
    fi

    # Parse status output
    local name status pid uptime
    read -r name status pid uptime <<< "$status_output"

    if [ "$format" = "json" ]; then
        echo "{\"name\":\"$name\",\"status\":\"$status\",\"pid\":\"$pid\",\"uptime\":\"$uptime\"}"
    else
        # Use different symbols based on status
        local symbol="⚠️"
        case "$status" in
            RUNNING) symbol="✅";;
            STOPPED) symbol="⛔";;
            FATAL)   symbol="💀";;
            *)      symbol="⚠️";;
        esac
        log_info "Service" "$symbol $name ($status) - PID: $pid, Uptime: $uptime"
    fi
}

# Description: View and follow logs for a service
# Options: --tail N, --follow, --error-only
# Example: worker service logs my-app --tail 100 --follow
follow_logs() {
    local service=$1
    shift

    # Check if service name is provided
    if [ -z "$service" ]; then
        log_error "Service" "Service name required"
        log_info "Service" "Usage: worker service logs <service-name> [options]"
        return 1
    fi

    # Check if service exists in config
    if ! yq e ".services[] | select(.name == \"$service\") | .name" "$SERVICES_CONFIG_FILE" 2>/dev/null | grep -q "$service"; then
        log_error "Service" "Service '$service' not found in configuration"
        return 1
    fi

    # Parse options
    local tail_lines=100
    local follow=false
    local error_only=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --tail)
                tail_lines=$2
                shift 2
                ;;
            --follow)
                follow=true
                shift
                ;;
            --error-only)
                error_only=true
                shift
                ;;
            *)
                log_error "Service" "Unknown option: $1"
                return 1
                ;;
        esac
    done

    # Build the tail command
    local cmd="tail"
    if [ "$follow" = true ]; then
        cmd+=" -f"
    fi
    cmd+=" -n $tail_lines"

    # Get log file paths
    local log_dir="/var/log/supervisor"
    local out_log="$log_dir/$service.out.log"
    local err_log="$log_dir/$service.err.log"

    # Check if log files exist
    if [ ! -f "$out_log" ] && [ ! -f "$err_log" ]; then
        log_error "Service" "No log files found for service '$service'"
        return 1
    fi

    # Show logs based on options
    if [ "$error_only" = true ]; then
        if [ -f "$err_log" ]; then
            $cmd "$err_log"
        else
            log_warn "Service" "No error log file found for service '$service'"
        fi
    else
        if [ -f "$out_log" ]; then
            $cmd "$out_log"
        fi
        if [ -f "$err_log" ]; then
            $cmd "$err_log"
        fi
    fi
}

# Description: Display current service configuration
# Example: worker service config [--format json]
service_show_config() {
    local format="$1"

    if [ ! -f "$SERVICES_CONFIG_FILE" ]; then
        log_warn "Service" "No services configuration found"
        log_info "Service" "Run 'worker service init' to create a new configuration"
        return 1
    fi

    if [ "$format" = "json" ]; then
        # Build JSON output with config file info and content
        echo "{"
        echo "  \"config_file\": \"$SERVICES_CONFIG_FILE\","
        echo -n "  \"content\": "
        yq e -o=json '.' "$SERVICES_CONFIG_FILE"
        echo "}"
    else
        log_info "Service" "Current service configuration:"
        log_info "Service" "Location: $SERVICES_CONFIG_FILE"
        echo ""
        cat "$SERVICES_CONFIG_FILE"
    fi
}

# Description: Start, stop, or restart a service
# Example: worker service restart my-app
manage_service() {
    local action=$1
    local service=$2
    
    # Check if service name is provided
    if [ -z "$service" ]; then
        log_error "Service" "Service name required for $action command"
        log_info "Service" "Usage: worker service $action <service-name>"
        return 1
    fi

    # Check if service exists in config
    if ! yq e ".services[] | select(.name == \"$service\") | .name" "$SERVICES_CONFIG_FILE" 2>/dev/null | grep -q "$service"; then
        log_error "Service" "Service '$service' not found in configuration"
        return 1
    fi

    # Source process manager functions but prevent main from running
    WORKER_SERVICE_MODE=1 source "${WORKER_LIB_DIR}/process_manager.sh" || return 1

    # Check if supervisor is running and config is up to date
    local supervisor_status
    supervisor_status=$(supervisorctl status 2>&1)
    local need_reload=false
    
    if echo "$supervisor_status" | grep -q "unix:///var/run/supervisor.sock no such file"; then
        log_warn "Service" "Supervisor is not running"
        log_info "Service" "Starting supervisor..."
        need_reload=true
    fi
    
    # Configure services
    if ! configure_services; then
        log_error "Service" "Failed to configure services"
        return 1
    fi
    
    if [ "$need_reload" = true ]; then
        # Start supervisord directly
        supervisord
        
        # Wait for supervisor to be ready
        local max_attempts=10
        local attempt=1
        while [ $attempt -le $max_attempts ]; do
            if supervisorctl status >/dev/null 2>&1; then
                break
            fi
            sleep 1
            attempt=$((attempt + 1))
        done
        
        if [ $attempt -gt $max_attempts ]; then
            log_error "Service" "Failed to start supervisor"
            return 1
        fi
    else
        # Reload config if supervisor is already running
        log_info "Service" "Reloading supervisor configuration..."
        supervisorctl reread
        supervisorctl update
    fi

    # Show action being taken
    case "$action" in
        start)
            log_info "Service" "🚀 Starting service: $service"
            ;;
        stop)
            log_info "Service" "🛑 Stopping service: $service"
            ;;
        restart)
            log_info "Service" "🔄 Restarting service: $service"
            ;;
    esac

    # Execute supervisorctl command and wait for result
    local result
    result=$(supervisorctl "$action" "$service" 2>&1)
    
    # Check for common errors
    if echo "$result" | grep -q "ERROR (no such process)"; then
        log_error "Service" "Service '$service' not found in supervisor"
        log_info "Service" "Run 'worker service config' to check your service configuration"
        return 1
    elif echo "$result" | grep -q "ERROR (already started)"; then
        log_warn "Service" "Service '$service' is already running"
        return 0
    elif echo "$result" | grep -q "ERROR (not running)"; then
        log_warn "Service" "Service '$service' is not running"
        return 0
    fi

    # Show the result
    echo "$result"

    # For restart/start, wait for service to be running
    if [ "$action" = "restart" ] || [ "$action" = "start" ]; then
        local max_attempts=10
        local attempt=1
        while [ $attempt -le $max_attempts ]; do
            if supervisorctl status "$service" | grep -q "RUNNING"; then
                break
            fi
            sleep 1
            attempt=$((attempt + 1))
        done
    fi

    # Show current status after action
    echo ""
    check_status "$service"
}
