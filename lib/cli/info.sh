#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Show help for info command
info_help() {
    cat << EOF
Display information about the UDX Worker image and runtime

Usage: worker info [command]

Available Commands:
  overview    Show a high-level overview of the worker image
  system      Show system information and resource usage
  config      Show configuration and settings
  services    Show available services and their status
  env         Show environment variables and settings
  auth        Show authentication and credentials status
  deps        Show installed dependencies and versions
  features    Show available features and capabilities
  paths       Show important filesystem paths
  logs        Show logging configuration and locations
  security    Show security settings and policies
  network     Show network configuration and ports
  version     Show detailed version information

Options:
  --format    Output format (text/json)
  --verbose   Show detailed information

Examples:
  worker info overview              # Get a quick overview of the worker
  worker info system --verbose      # Show detailed system information
  worker info deps --format json    # List dependencies in JSON format
  worker info features              # Show available features
EOF
}

# Show general information
show_info() {
    local format=${1:-text}
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"version\": \"$VERSION\","
                echo "  \"os\": \"$(uname -s)\","
                echo "  \"architecture\": \"$(uname -m)\","
                echo "  \"hostname\": \"$(hostname)\","
                echo "  \"user\": \"$USER\","
                echo "  \"paths\": {"
                echo "    \"base\": \"$WORKER_BASE_DIR\","
                echo "    \"config\": \"$WORKER_CONFIG_DIR\","
                echo "    \"apps\": \"$WORKER_APP_DIR\","
                echo "    \"data\": \"$WORKER_DATA_DIR\","
                echo "    \"lib\": \"$WORKER_LIB_DIR\","
                echo "    \"bin\": \"$WORKER_BIN_DIR\""
                echo "  },"
                echo "  \"cloud\": {"
                echo "    \"gcp_config\": \"$CLOUDSDK_CONFIG\","
                echo "    \"aws_config\": \"$AWS_CONFIG_FILE\","
                echo "    \"azure_config\": \"$AZURE_CONFIG_DIR\""
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            echo "UDX Worker Information"
            echo "====================="
            echo
            echo "Version: $VERSION"
            echo
            echo "System"
            echo "------"
            echo "OS: $(uname -s)"
            echo "Architecture: $(uname -m)"
            echo "Hostname: $(hostname)"
            echo "User: $USER"
            echo
            echo "Paths"
            echo "-----"
            echo "Base Directory: $WORKER_BASE_DIR"
            echo "Config Directory: $WORKER_CONFIG_DIR"
            echo "Apps Directory: $WORKER_APP_DIR"
            echo "Data Directory: $WORKER_DATA_DIR"
            echo "Library Directory: $WORKER_LIB_DIR"
            echo "Binary Directory: $WORKER_BIN_DIR"
            echo
            echo "Cloud Configuration"
            echo "------------------"
            echo "GCP Config: $CLOUDSDK_CONFIG"
            echo "AWS Config: $AWS_CONFIG_FILE"
            echo "Azure Config: $AZURE_CONFIG_DIR"
            ;;
        *)
            log_error "Info" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Show system information
show_system_info() {
    local format=${1:-text}
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"kernel\": \"$(uname -r)\","
                echo "  \"os\": {"
                echo "    \"name\": \"$(uname -s)\","
                echo "    \"version\": \"$(cat /etc/os-release | grep VERSION= | cut -d'\"' -f2)\""
                echo "  },"
                echo "  \"cpu\": {"
                echo "    \"architecture\": \"$(uname -m)\","
                echo "    \"cores\": $(nproc),"
                echo "    \"model\": \"$(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)\""
                echo "  },"
                echo "  \"memory\": {"
                echo "    \"total\": $(free -b | grep Mem | awk '{print $2}'),"
                echo "    \"free\": $(free -b | grep Mem | awk '{print $4}')"
                echo "  },"
                echo "  \"disk\": {"
                echo "    \"total\": $(df -B1 / | tail -1 | awk '{print $2}'),"
                echo "    \"free\": $(df -B1 / | tail -1 | awk '{print $4}')"
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            echo "System Information"
            echo "=================="
            echo
            echo "Kernel: $(uname -r)"
            echo
            echo "Operating System"
            echo "----------------"
            echo "Name: $(uname -s)"
            echo "Version: $(cat /etc/os-release | grep VERSION= | cut -d'\"' -f2)"
            echo
            echo "CPU"
            echo "---"
            echo "Architecture: $(uname -m)"
            echo "Cores: $(nproc)"
            echo "Model: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d':' -f2 | xargs)"
            echo
            echo "Memory"
            echo "------"
            echo "Total: $(free -h | grep Mem | awk '{print $2}')"
            echo "Free: $(free -h | grep Mem | awk '{print $4}')"
            echo
            echo "Disk"
            echo "----"
            echo "Total: $(df -h / | tail -1 | awk '{print $2}')"
            echo "Free: $(df -h / | tail -1 | awk '{print $4}')"
            ;;
        *)
            log_error "Info" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Get available CLI modules and their help info
get_cli_modules() {
    local modules_dir="${WORKER_LIB_DIR}/cli"
    local modules={}
    
    # Initialize modules array
    declare -A modules
    
    # Scan through CLI modules
    for module in "$modules_dir"/*.sh; do
        local name=$(basename "$module" .sh)
        local description=""
        local commands=()
        
        # Extract help function content
        if grep -q "${name}_help()" "$module"; then
            # Get description from help function
            description=$(grep -A 1 "${name}_help()" "$module" | grep -v "${name}_help()" | grep -v "^{" | head -n 1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            # Get available commands
            while IFS= read -r line; do
                if [[ $line =~ ^[[:space:]]+([a-zA-Z0-9_-]+)[[:space:]]+(.+)$ ]]; then
                    commands+=("${BASH_REMATCH[1]}:${BASH_REMATCH[2]}")
                fi
            done < <(grep -A 20 "Available Commands:" "$module" | grep -B 20 "Examples:" | grep "^[[:space:]]*[a-zA-Z]")
        fi
        
        modules[$name]="$description|${commands[*]}"
    done
    
    echo "$(declare -p modules)"
}

# Show overview of the worker
show_overview() {
    local format=${1:-text}
    local -A modules
    eval "$(get_cli_modules)"
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"name\": \"UDX Worker\","
                echo "  \"description\": \"Universal Data Exchange Worker for managing cloud services and data pipelines\","
                echo "  \"version\": \"$VERSION\","
                echo "  \"modules\": {"
                
                local first=true
                for module in "${!modules[@]}"; do
                    IFS='|' read -r description commands <<< "${modules[$module]}"
                    
                    if [ "$first" = true ]; then
                        first=false
                    else
                        echo ","
                    fi
                    
                    echo "    \"$module\": {"
                    echo "      \"description\": \"$description\","
                    echo "      \"commands\": ["
                    
                    IFS=' ' read -ra cmd_array <<< "$commands"
                    local first_cmd=true
                    for cmd in "${cmd_array[@]}"; do
                        IFS=':' read -r cmd_name cmd_desc <<< "$cmd"
                        if [ "$first_cmd" = true ]; then
                            first_cmd=false
                        else
                            echo ","
                        fi
                        echo "        {"
                        echo "          \"name\": \"$cmd_name\","
                        echo "          \"description\": \"$cmd_desc\""
                        echo -n "        }"
                    done
                    echo ""
                    echo "      ]"
                    echo -n "    }"
                done
                echo ""
                echo "  },"
                echo "  \"dependencies\": {"
                echo "    \"runtime\": \"$(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)\","
                echo "    \"python\": \"$(python3 --version | cut -d ' ' -f 2)\","
                echo "    \"supervisor\": \"$(supervisord -v)\""
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            cat << EOF
UDX Worker Overview
==================

Description: Universal Data Exchange Worker for managing cloud services and data pipelines
Version: ${VERSION}

Available Modules
----------------
EOF
            for module in "${!modules[@]}"; do
                IFS='|' read -r description commands <<< "${modules[$module]}"
                echo -e "\n• $module - $description"
                
                if [ -n "$commands" ]; then
                    echo "  Commands:"
                    IFS=' ' read -ra cmd_array <<< "$commands"
                    for cmd in "${cmd_array[@]}"; do
                        IFS=':' read -r cmd_name cmd_desc <<< "$cmd"
                        echo "    ✓ $cmd_name - $cmd_desc"
                    done
                fi
            done
            
            echo -e "\nSystem Information
------------------"
            echo "• Runtime: $(cat /etc/os-release | grep PRETTY_NAME | cut -d '"' -f 2)"
            echo "• Python: $(python3 --version | cut -d ' ' -f 2)"
            echo "• Supervisor: $(supervisord -v)"
            
            echo -e "\nFor more information:"
            echo "• Run 'worker help' for usage instructions"
            echo "• Run 'worker info <module>' for detailed module information"
            echo "• Run 'worker <module> help' for module-specific help"
            ;;
        *)
            log_error "Info" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Show available features
show_features() {
    local format=${1:-text}
    local -A modules
    eval "$(get_cli_modules)"
    
    case $format in
        json)
            {
                echo "{"
                echo "  \"features\": {"
                
                local first=true
                for module in "${!modules[@]}"; do
                    IFS='|' read -r description commands <<< "${modules[$module]}"
                    
                    if [ "$first" = true ]; then
                        first=false
                    else
                        echo ","
                    fi
                    
                    # Convert module name to feature key
                    local feature_key=$(echo "$module" | tr '-' '_')
                    
                    echo "    \"$feature_key\": {"
                    echo "      \"description\": \"$description\","
                    echo "      \"commands\": ["
                    
                    IFS=' ' read -ra cmd_array <<< "$commands"
                    local first_cmd=true
                    for cmd in "${cmd_array[@]}"; do
                        IFS=':' read -r cmd_name cmd_desc <<< "$cmd"
                        if [ "$first_cmd" = true ]; then
                            first_cmd=false
                        else
                            echo ","
                        fi
                        echo "        {"
                        echo "          \"name\": \"$cmd_name\","
                        echo "          \"description\": \"$cmd_desc\""
                        echo -n "        }"
                    done
                    echo ""
                    echo "      ]"
                    echo -n "    }"
                done
                echo ""
                echo "  }"
                echo "}"
            } | jq '.'
            ;;
        text)
            cat << EOF
UDX Worker Features
==================

EOF
            local count=1
            for module in "${!modules[@]}"; do
                IFS='|' read -r description commands <<< "${modules[$module]}"
                echo -e "\n$count. ${module^}"
                echo "   Description: $description"
                
                if [ -n "$commands" ]; then
                    echo "   Commands:"
                    IFS=' ' read -ra cmd_array <<< "$commands"
                    for cmd in "${cmd_array[@]}"; do
                        IFS=':' read -r cmd_name cmd_desc <<< "$cmd"
                        echo "     • $cmd_name - $cmd_desc"
                    done
                fi
                ((count++))
            done
            echo -e "\nUse 'worker <feature> help' for detailed feature documentation"
            ;;
        *)
            log_error "Info" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Handle info commands
info_handler() {
    local command=$1
    shift
    
    case $command in
        overview)
            show_overview "$@"
            ;;
        system)
            show_system_info "$@"
            ;;
        features)
            show_features "$@"
            ;;
        deps)
            show_deps "$@"
            ;;
        config)
            show_config "$@"
            ;;
        services)
            show_services "$@"
            ;;
        env)
            show_env "$@"
            ;;
        auth)
            show_auth "$@"
            ;;
        paths)
            show_paths "$@"
            ;;
        logs)
            show_logs "$@"
            ;;
        security)
            show_security "$@"
            ;;
        network)
            show_network "$@"
            ;;
        version)
            show_version "$@"
            ;;
        help|"")
            info_help
            ;;
        *)
            log_error "Info" "Unknown command: $command"
            info_help
            return 1
            ;;
    esac
}
