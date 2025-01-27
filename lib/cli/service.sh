#!/bin/bash

service_handler() {
    case $1 in
        list)
            list_services
        ;;
        status)
            check_status "$2"
        ;;
        logs)
            follow_logs "$2"
        ;;
        errors)
            follow_logs "$2" "err"
        ;;
        config)
            show_config
        ;;
        start|stop|restart)
            manage_service "$1" "$2"
        ;;
        *)
            echo "Usage: $0 {list|status|logs|config|start|stop|restart}"
            exit 1
        ;;
    esac
}

# Function to list all services
list_services() {
    # Capture the output of supervisorctl status
    local services_status
    services_status=$(supervisorctl status 2>&1) # Also capture stderr to handle error messages
    
    # Check if Supervisor is not running, not accessible, or if there are no managed services
    if [[ -z "$services_status" ]] || echo "$services_status" | grep -Eq 'no such|ERROR'; then
        echo "No services are currently managed."
        exit 1
    fi
    
    echo "Listing all managed services:"
    local i=1
    echo "$services_status" | while read -r line; do
        echo "$i. $line"
        ((i++))
    done
}

# Function to check the status of one or all services
check_status() {
    # Require a service name for this function
    if [ -z "$1" ]; then
        echo "Error: No service name provided."
        echo "Usage: $0 status <service_name>"
        exit 1
    fi
    
    # Attempt to capture the status of the specific service, including errors
    local service_status
    service_status=$(supervisorctl status "$1" 2>&1)
    
    # Check if Supervisor is not running, not accessible, or if the service does not exist
    if [[ -z "$service_status" ]] || echo "$service_status" | grep -Eq 'no such|ERROR'; then
        echo "The service '$1' does not exist."
        exit 1
    fi
    
    # Directly output the captured service status
    echo "$service_status"
}

# Function to follow logs for a specific service
follow_logs() {
    if [ -z "$1" ]; then
        echo "Error: No service name provided."
        echo "Usage: $0 logs <service_name>"
        exit 1
    fi
    
    local logfile="/var/log/supervisor/$1"
    local type=${2:-out}  # Default to 'out' if not specified
    logfile="$logfile.$type.log"
    
    if [ ! -f "$logfile" ]; then
        echo "Log file does not exist: $logfile"
        exit 1
    fi
    
    tail -f "$logfile"
}

# Function to show supervisor configuration
show_config() {
    if [ ! -f "/etc/supervisord.conf" ]; then
        echo "Configuration file is not generated since no services are managed."
        exit 1
    fi
    cat /etc/supervisord.conf
}

# Function to start, stop, or restart a service
manage_service() {
    if [ -z "$2" ]; then
        echo "Error: No service name provided."
        echo "Usage: $0 $1 <service_name>"
        exit 1
    fi
    
    if [ ! -e "/var/run/supervisor/supervisord.sock" ]; then
        echo "Error: Service doesn't exist."
        exit 1
    fi
    
    supervisorctl "$1" "$2"
}