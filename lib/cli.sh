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
    tail -f /var/log/supervisor/"$1"-*.log
}

# Function to show supervisor configuration
show_config() {
    cat /etc/supervisor/supervisord.conf
}

# Function to start, stop, or restart a service
manage_service() {
    supervisorctl "$1" "$2"
}

# CLI Interface
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
    config)
        show_config
        ;;
    start|stop|restart)
        manage_service "$1" "$2"
        ;;
    *)
        echo "Usage: $0 {list|status [service_name]|logs <service_name>|config|start <service_name>|stop <service_name>|restart <service_name>}"
        exit 1
        ;;
esac