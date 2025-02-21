#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Show help for health command
health_help() {
    cat << EOF
Check system health and run diagnostics

Usage: worker health [command]

Available Commands:
  status      Show current health status

Options:
  --format    Output format (text|json)

Examples:
  worker health status
  worker health status --format json
EOF
}

# Description: Check system health metrics
# Example: worker health status [--format json]
check_health() {
    local format="text"
    local failed=0
    
    while [ $# -gt 0 ]; do
        case $1 in
            --format)
                format=$2
                shift 2
                ;;
            *)
                log_error "Health" "Unknown option: $1"
                return 1
                ;;
        esac
    done
    
    if [ "$format" != "json" ]; then
        log_info "Health" "Running health check..."
    fi
    
    # Check system resources
    check_system_resources || failed=1
    
    # Gather all data
    local timestamp
    local disk_usage
    local mem_total
    local mem_used
    local mem_usage
    local load_avg
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    mem_total=$(free -b | awk '/Mem:/ {printf "%.2f", $2/1024/1024/1024}')
    mem_used=$(free -b | awk '/Mem:/ {printf "%.2f", $3/1024/1024/1024}')
    mem_usage=$(free | awk '/Mem:/ {printf("%.0f", $3/$2 * 100)}')
    load_avg=$(uptime | awk -F'load average:' '{print $2}' | cut -d, -f1 | tr -d ' ')
    
    if [ "$format" = "json" ]; then
        {
            echo "{"
            echo "  \"timestamp\": \"$timestamp\","
            echo "  \"status\": \"$([ $failed -eq 0 ] && echo "healthy" || echo "unhealthy")\","
            echo "  \"disk\": {"
            echo "    \"usage_percent\": $disk_usage"
            echo "  },"
            echo "  \"memory\": {"
            echo "    \"total_gb\": $mem_total,"
            echo "    \"used_gb\": $mem_used,"
            echo "    \"usage_percent\": $mem_usage"
            echo "  },"
            echo "  \"load_average\": $load_avg"
            echo "}"
        }
    else
        if [ $failed -eq 0 ]; then
            log_success "Health" "All health checks passed"
        else
            log_error "Health" "Some health checks failed"
        fi
    fi
    
    return $failed
}

# Description: Check system resource usage (disk, memory, CPU)
# Example: worker health status
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



# Handle health commands
health_handler() {
    local command=$1
    shift

    case $command in
        status)
            check_health "$@"
            ;;
        ""|-h|--help)
            health_help
            ;;
        *)
            log_error "Health" "Unknown command: $command"
            health_help
            return 1
            ;;
    esac
}
