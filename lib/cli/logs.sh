#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh

# Show help for logs command
logs_help() {
    cat << EOF
View and manage logs

Usage: worker logs [command]

Available Commands:
  show        Show logs for a service
  follow      Follow logs in real-time
  search      Search logs for pattern
  export      Export logs to file
  clean       Clean old logs

Options:
  --service   Service name (required for show/follow)
  --type      Log type (out/err/all, default: all)
  --lines     Number of lines (default: 100)
  --since     Show logs since timestamp
  --until     Show logs until timestamp
  --pattern   Search pattern
  --format    Output format (text/json)

Examples:
  worker logs show --service myapp
  worker logs follow --service myapp --type err
  worker logs search --pattern "error"
  worker logs export --service myapp --since "2024-01-01"
  worker logs clean --older-than 7d
EOF
}

# Get log file path
get_log_file() {
    local service=$1
    local type=${2:-all}
    
    case $type in
        out)
            echo "/var/log/supervisor/${service}-stdout.log"
            ;;
        err)
            echo "/var/log/supervisor/${service}-stderr.log"
            ;;
        all)
            echo "/var/log/supervisor/${service}-*.log"
            ;;
        *)
            log_error "Logs" "Invalid log type: $type"
            return 1
            ;;
    esac
}

# Show logs
show_logs() {
    local service=$1
    local type=${2:-all}
    local lines=${3:-100}
    local since=$4
    local until=$5
    
    if [ -z "$service" ]; then
        log_error "Logs" "Service name is required"
        return 1
    fi
    
    local log_file
    log_file=$(get_log_file "$service" "$type")
    
    if [ ! -f "$log_file" ]; then
        log_error "Logs" "Log file not found: $log_file"
        return 1
    fi
    
    local cmd="tail -n $lines"
    
    if [ -n "$since" ]; then
        cmd="$cmd | awk -v since=\"\$since\" '\$0 >= since'"
    fi
    
    if [ -n "$until" ]; then
        cmd="$cmd | awk -v until=\"\$until\" '\$0 <= until'"
    fi
    
    eval "$cmd $log_file"
}

# Follow logs
follow_logs() {
    local service=$1
    local type=${2:-all}
    
    if [ -z "$service" ]; then
        log_error "Logs" "Service name is required"
        return 1
    fi
    
    local log_file
    log_file=$(get_log_file "$service" "$type")
    
    if [ ! -f "$log_file" ]; then
        log_error "Logs" "Log file not found: $log_file"
        return 1
    fi
    
    tail -f "$log_file"
}

# Search logs
search_logs() {
    local pattern=$1
    local service=$2
    local type=${3:-all}
    
    if [ -z "$pattern" ]; then
        log_error "Logs" "Search pattern is required"
        return 1
    fi
    
    local log_file
    if [ -n "$service" ]; then
        log_file=$(get_log_file "$service" "$type")
    else
        log_file="/var/log/supervisor/*.log"
    fi
    
    grep -n "$pattern" $log_file
}

# Export logs
export_logs() {
    local service=$1
    local type=${2:-all}
    local since=$3
    local until=$4
    local format=${5:-text}
    
    if [ -z "$service" ]; then
        log_error "Logs" "Service name is required"
        return 1
    fi
    
    local log_file
    log_file=$(get_log_file "$service" "$type")
    
    if [ ! -f "$log_file" ]; then
        log_error "Logs" "Log file not found: $log_file"
        return 1
    fi
    
    local output_file="${service}_logs_$(date +%Y%m%d_%H%M%S)"
    
    case $format in
        json)
            output_file="$output_file.json"
            awk '{printf "{\\"timestamp\\":\\"%s\\",\\"message\\":\\"%s\\"}\\n", $1, substr($0,index($0,$2))}' "$log_file" > "$output_file"
            ;;
        text)
            output_file="$output_file.log"
            if [ -n "$since" ] || [ -n "$until" ]; then
                awk -v since="$since" -v until="$until" '
                    ($0 >= since) && ($0 <= until || until=="")
                ' "$log_file" > "$output_file"
            else
                cp "$log_file" "$output_file"
            fi
            ;;
        *)
            log_error "Logs" "Unknown format: $format"
            return 1
            ;;
    esac
    
    log_success "Logs" "Logs exported to $output_file"
}

# Clean old logs
clean_logs() {
    local older_than=${1:-7d}  # Default: 7 days
    
    find /var/log/supervisor -name "*.log" -type f -mtime +"${older_than%d}" -delete
    
    log_success "Logs" "Cleaned logs older than $older_than"
}

# Parse command line arguments
parse_args() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --service)
                service=$2
                shift 2
                ;;
            --type)
                type=$2
                shift 2
                ;;
            --lines)
                lines=$2
                shift 2
                ;;
            --since)
                since=$2
                shift 2
                ;;
            --until)
                until=$2
                shift 2
                ;;
            --pattern)
                pattern=$2
                shift 2
                ;;
            --format)
                format=$2
                shift 2
                ;;
            --older-than)
                older_than=$2
                shift 2
                ;;
            *)
                args+=("$1")
                shift
                ;;
        esac
    done
    set -- "${args[@]}"
}

# Handle logs commands
logs_handler() {
    local cmd=$1
    shift
    
    # Parse command line arguments
    parse_args "$@"
    
    case $cmd in
        show)
            show_logs "$service" "$type" "$lines" "$since" "$until"
            ;;
        follow)
            follow_logs "$service" "$type"
            ;;
        search)
            search_logs "$pattern" "$service" "$type"
            ;;
        export)
            export_logs "$service" "$type" "$since" "$until" "$format"
            ;;
        clean)
            clean_logs "$older_than"
            ;;
        help)
            logs_help
            ;;
        *)
            log_error "Logs" "Unknown command: $cmd"
            logs_help
            exit 1
            ;;
    esac
}
