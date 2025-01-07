#!/bin/bash

# Function to list all services
list_services() {
    supervisorctl status
}

# Function to check the status of one or all services
check_status() {
    if [ -z "$1" ]; then
        supervisorctl status
    else
        supervisorctl status "$1"
    fi
}

# Function to follow logs for a specific service
follow_logs() {
    local type=${2:-out}  # Use 'out' if $2 is unset or null.
    tail -f /var/log/supervisor/"$1"."$type".log
}

# Function to show supervisor configuration
show_config() {
    cat /etc/supervisord.conf
}

# Function to start, stop, or restart a service
manage_service() {
    supervisorctl "$1" "$2"
}

# CLI Interface
case $1 in
    service)
        shift # Shift the arguments to the left, so $2 becomes $1, $3 becomes $2, etc.
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
            start)
                manage_service start "$2"
            ;;
            stop)
                manage_service stop "$2"
            ;;
            restart)
                manage_service restart "$2"
            ;;
            *)
                echo "Usage: $0 service {list|status [service_name]|logs <service_name>|config|start <service_name>|stop <service_name>|restart <service_name>}"
                exit 1
            ;;
        esac
    ;;
    *)
        echo "Usage: $0 {service {list|status [service_name]|logs <service_name>|config|start <service_name>|stop <service_name>|restart <service_name>}}"
        exit 1
    ;;
esac