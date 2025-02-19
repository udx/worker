#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh

# Show help for health command
health_help() {
    cat << EOF
Check system health and run diagnostics

Usage: worker health [command]

Available Commands:
  check       Run health check
  status      Show current health status
  diag        Run diagnostics
  report      Generate health report

Examples:
  worker health check
  worker health status
  worker health diag
  worker health report --format json
EOF
}

# Description: Run comprehensive health check of the worker
# Example: worker health check
check_health() {
    log_info "Health" "Running health check..."
    local failed=0
    
    # Check system resources
    check_system_resources || failed=1
    
    # Check supervisor status
    check_supervisor_status || failed=1
    
    # Check service health
    check_services_health || failed=1
    
    # Check authentication status
    check_auth_status || failed=1
    
    if [ $failed -eq 0 ]; then
        log_success "Health" "All health checks passed"
    else
        log_error "Health" "Some health checks failed"
        return 1
    fi
}

# Description: Check system resource usage (disk, memory, CPU)
# Example: worker health check system
check_system_resources() {
    local failed=0
    
    # Check disk space
    local disk_usage
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    if [ "$disk_usage" -gt 90 ]; then
        log_error "Health" "Disk usage is critical: ${disk_usage}%"
        failed=1
    else
        log_success "Health" "Disk usage is normal: ${disk_usage}%"
    fi
    
    # Check memory
    local mem_usage
    mem_usage=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')
    if [ "$mem_usage" -gt 90 ]; then
        log_error "Health" "Memory usage is critical: ${mem_usage}%"
        failed=1
    else
        log_success "Health" "Memory usage is normal: ${mem_usage}%"
    fi
    
    # Check load average
    local load_avg
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1)
    if [ "${load_avg%.*}" -gt 4 ]; then
        log_error "Health" "Load average is high: $load_avg"
        failed=1
    else
        log_success "Health" "Load average is normal: $load_avg"
    fi
    
    return $failed
}

# Description: Check if supervisor is running and responsive
# Example: worker health check supervisor
check_supervisor_status() {
    if ! pgrep -f supervisord > /dev/null; then
        log_error "Health" "Supervisor is not running"
        return 1
    fi
    
    if ! supervisorctl status > /dev/null; then
        log_error "Health" "Supervisor is not responding"
        return 1
    fi
    
    log_success "Health" "Supervisor is running and responsive"
    return 0
}

# Description: Check health status of all managed services
# Example: worker health check services
check_services_health() {
    local failed=0
    local services_status
    
    services_status=$(supervisorctl status)
    if [ $? -ne 0 ]; then
        log_error "Health" "Failed to get services status"
        return 1
    fi
    
    echo "$services_status" | while read -r line; do
        local service_name status
        service_name=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        
        if [ "$status" != "RUNNING" ]; then
            log_error "Health" "Service $service_name is not running (status: $status)"
            failed=1
        else
            log_success "Health" "Service $service_name is running"
        fi
    done
    
    return $failed
}

# Description: Check authentication status for all providers
# Example: worker health check auth
check_auth_status() {
    local failed=0
    
    # Check each provider
    for provider in aws gcp azure bitwarden; do
        if is_provider_configured "$provider"; then
            if ! test_provider_auth "$provider"; then
                log_error "Health" "Authentication failed for $provider"
                failed=1
            else
                log_success "Health" "Authentication successful for $provider"
            fi
        fi
    done
    
    return $failed
}

# Description: Generate detailed health report
# Options: --format text|json
# Example: worker health report --format json
generate_report() {
    local format=${1:-text}
    local report_file
    report_file=$(mktemp)
    
    {
        echo "Worker Health Report"
        echo "==================="
        echo "Timestamp: $(date)"
        echo
        
        echo "System Resources:"
        echo "----------------"
        df -h /
        echo
        free -h
        echo
        uptime
        echo
        
        echo "Services Status:"
        echo "---------------"
        supervisorctl status
        echo
        
        echo "Authentication Status:"
        echo "--------------------"
        for provider in aws gcp azure bitwarden; do
            if is_provider_configured "$provider"; then
                echo "$provider: Configured"
            else
                echo "$provider: Not configured"
            fi
        done
    } > "$report_file"
    
    case $format in
        json)
            # Convert report to JSON format
            jq -R -s '{
                timestamp: now,
                system_resources: {
                    disk: (input | match("^/dev.*$")),
                    memory: (input | match("^Mem:.*$")),
                    load: (input | match("^load average:.*$"))
                },
                services: (input | match("^RUNNING.*$")),
                auth: (input | match("^.*: Configured$"))
            }' "$report_file"
            ;;
        text)
            cat "$report_file"
            ;;
        *)
            log_error "Health" "Unknown format: $format"
            rm -f "$report_file"
            return 1
            ;;
    esac
    
    rm -f "$report_file"
}

# Handle health commands
health_handler() {
    local cmd=$1
    shift
    
    case $cmd in
        check)
            check_health
            ;;
        status)
            check_health --quiet
            ;;
        diag)
            check_health --verbose
            ;;
        report)
            generate_report "$@"
            ;;
        help)
            health_help
            ;;
        *)
            log_error "Health" "Unknown command: $cmd"
            health_help
            exit 1
            ;;
    esac
}
