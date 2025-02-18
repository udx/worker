#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh

service_handler() {
    local cmd=$1
    shift  # Remove the command from args

    case $cmd in
        list)
            list_services
        ;;
        status)
            check_status "$1"
        ;;
        logs)
            follow_logs "$@"
        ;;
        errors)
            follow_logs "$1" "err"
        ;;
        config)
            show_config
        ;;
        start|stop|restart)
            manage_service "$cmd" "$1"
        ;;
        *)
            log_warn "CLI" "Usage: $0 {list|status|logs|config|start|stop|restart}"
            exit 1
        ;;
    esac
}

# Show help for service command
service_help() {
    cat << EOF
Manage UDX Worker services and applications

Usage: worker service [command] [options]

Commands:
  list              List all configured services and their status
  status [name]     Show status of all services or a specific service
  logs [name]       View logs for all services or a specific service
  errors [name]     View error logs for all services or a specific service
  config            Show current service configuration
  start [name]      Start a service
  stop [name]       Stop a service
  restart [name]    Restart a service

Configuration:
  Services are configured in: ${HOME}/.config/worker/services.yaml

Example service configuration:
  version: "1.0"
  services:
    my-app:
      name: "my-app"
      command: "python app.py"
      working_dir: "/opt/worker/apps"
      autostart: true
      autorestart: true
      environment:
        APP_PORT: "8080"

Examples:
  worker service list          # List all services
  worker service logs my-app   # View logs for my-app
  worker service start my-app  # Start my-app service
EOF
}

# Function to list all services
list_services() {
    # Capture the output of supervisorctl status
    local services_status
    services_status=$(supervisorctl status 2>&1) # Also capture stderr to handle error messages
    
    # Check if Supervisor is not running, not accessible, or if there are no managed services
    if [[ -z "$services_status" ]] || echo "$services_status" | grep -Eq 'no such|ERROR'; then
        log_info "No services are currently managed."
        log_info "To configure services, create ${HOME}/.config/worker/services.yaml"
        log_info "Run 'worker help service' for configuration examples."
        return 0
    fi
    
    log_info "Managed services:"
    local i=1
    echo "$services_status" | while read -r line; do
        log_info "$i. $line"
        ((i++))
    done
}

# Function to check the status of one or all services
check_status() {
    # Require a service name for this function
    if [ -z "$1" ]; then
        log_warn "Service" "Error: No service name provided."
        log_warn "Service" "Usage: $0 status <service_name>"
        exit 1
    fi
    
    # Attempt to capture the status of the specific service, including errors
    local service_status
    service_status=$(supervisorctl status "$1" 2>&1)
    
    # Check if Supervisor is not running, not accessible, or if the service does not exist
    if [[ -z "$service_status" ]] || echo "$service_status" | grep -Eq 'no such|ERROR'; then
        log_warn "Service" "The service '$1' does not exist."
        exit 1
    fi
    
    # Directly output the captured service status
    echo "$service_status"
}

# Function to follow logs for a specific service
follow_logs() {
    local service_name=""
    local type="out"
    local lines=20
    local nostream=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lines=*)
                lines="${1#*=}"
                ;;
            --lines)
                shift
                if [[ -n "$1" && "$1" =~ ^[0-9]+$ ]]; then
                    lines="$1"
                fi
                ;;
            --nostream)
                nostream=true
                ;;
            err)
                type="err"
                ;;
            *)
                if [[ -z "$service_name" ]]; then
                    service_name="$1"
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$service_name" ]]; then
        log_error "Service" "Error: No service name provided."
        log_error "Service" "Usage: $0 logs <service_name> [--lines N] [--nostream]"
        exit 1
    fi
    
    local logfile="/var/log/supervisor/$service_name"
    logfile="$logfile.$type.log"
    
    if [[ ! -f "$logfile" ]]; then
        log_error "Service" "Log file does not exist: $logfile"
        exit 1
    fi

    # Ensure lines is a valid number
    if ! [[ "$lines" =~ ^[0-9]+$ ]]; then
        log_error "Service" "Invalid line count: $lines"
        exit 1
    fi
    
    if [ "$nostream" = true ]; then
        # Just show the last N lines without following
        tail -n "$lines" "$logfile"
    else
        # Show the last N lines and follow
        exec tail -n "$lines" -f "$logfile"
    fi
}

# Function to show supervisor configuration
show_config() {
    if [ ! -f "/etc/supervisord.conf" ]; then
        log_error "Service" "Configuration file is not generated since no services are managed."
        exit 1
    fi
    cat /etc/supervisord.conf
}

# Function to start, stop, or restart a service
manage_service() {
    if [ -z "$2" ]; then
        log_error "Service" "Error: No service name provided."
        log_warn "Service" "Usage: $0 $1 <service_name>"
        exit 1
    fi
    
    if [ ! -e "/var/run/supervisor/supervisord.sock" ]; then
        log_error "Service" "Error: Service doesn't exist."
        exit 1
    fi
    
    supervisorctl "$1" "$2"
}