#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source "${WORKER_LIB_DIR}/utils.sh"

# Get command metadata by scanning function contents
get_command_metadata() {
    local commands={}
    declare -A commands
    local current_file="${BASH_SOURCE[0]}"

    # Scan the current file for show_* functions and their metadata
    while IFS= read -r line; do
        # Match show_* function definitions
        if [[ $line =~ ^show_([a-z_]+)[[:space:]]*\(\)[[:space:]]*\{[[:space:]]*$ ]]; then
            local cmd=${BASH_REMATCH[1]}
            local desc=""
            local options=""
            local example=""

            # Skip internal functions like show_help
            [[ $cmd == "help" ]] && continue

            # Look for metadata in comments above function
            local temp_file=$(mktemp)
            grep -B 10 "^show_${cmd}()" "$current_file" > "$temp_file"
            
            # Get description
            desc=$(grep -B 10 "^show_${cmd}()" "$temp_file" | grep '^# Description:' | tail -n 1 | sed 's/^# Description:[[:space:]]*//')
            if [ -z "$desc" ]; then
                desc=$(grep -B 10 "^show_${cmd}()" "$temp_file" | grep '^#[[:space:]]' | tail -n 1 | sed 's/^#[[:space:]]*//')
            fi
            if [ -z "$desc" ]; then
                desc="Show ${cmd//_/ } information"
            fi

            # Get options
            options=$(grep -B 10 "^show_${cmd}()" "$temp_file" | grep '^# Options:' | tail -n 1 | sed 's/^# Options:[[:space:]]*//')
            if [ -z "$options" ] && grep -q 'format=' "$temp_file"; then
                options="--format text|json"
            fi
            if grep -q 'verbose=' "$temp_file"; then
                [[ -n "$options" ]] && options="$options, " 
                options+="--verbose"
            fi

            # Get example
            example=$(grep -B 10 "^show_${cmd}()" "$temp_file" | grep '^# Example:' | tail -n 1 | sed 's/^# Example:[[:space:]]*//')
            if [ -z "$example" ] && [ -n "$options" ]; then
                if [[ $options == *"format"* ]]; then
                    example="worker info $cmd --format json"
                elif [[ $options == *"verbose"* ]]; then
                    example="worker info $cmd --verbose"
                fi
            fi

            rm "$temp_file"

            # Store metadata
            commands[$cmd]="$desc|$options|$example"
        fi
    done < "$current_file"

    echo "$(declare -p commands)"
}

# Show help for info command
info_help() {
    local -A commands
    eval "$(get_command_metadata)"

    # Find the longest command name for proper padding
    local max_length=0
    for cmd in "${!commands[@]}"; do
        local len=${#cmd}
        if ((len > max_length)); then
            max_length=$len
        fi
    done

    # Add padding for alignment
    max_length=$((max_length + 2))

    cat << EOF
Display information about the UDX Worker image and runtime

Usage: worker info [command]

Available Commands:
EOF

    # Sort commands alphabetically and display
    local sorted_commands=($(echo "${!commands[@]}" | tr ' ' '\n' | sort))
    for cmd in "${sorted_commands[@]}"; do
        IFS='|' read -r desc options example <<< "${commands[$cmd]}"
        printf "  %-${max_length}s %s\n" "$cmd" "$desc"
    done

    # Collect unique options from all commands
    local all_options=""
    for cmd in "${!commands[@]}"; do
        IFS='|' read -r _ options _ <<< "${commands[$cmd]}"
        if [ -n "$options" ]; then
            all_options="$all_options $options"
        fi
    done

    # Display unique options
    if [ -n "$all_options" ]; then
        echo -e "\nOptions:"
        echo "$all_options" | tr ',' '\n' | tr ' ' '\n' | sort -u | grep -v '^$' | while read -r opt; do
            printf "  %s\n" "$opt"
        done
    fi

    # Display examples for commands that have them
    local has_examples=false
    for cmd in "${sorted_commands[@]}"; do
        IFS='|' read -r desc options example <<< "${commands[$cmd]}"
        if [ -n "$example" ]; then
            if ! $has_examples; then
                echo -e "\nExamples:"
                has_examples=true
            fi
            printf "  %-45s # %s\n" "$example" "$desc"
        fi
    done

    echo
}

# Description: Display general information about the worker
# Options: --format text|json
# Example: worker info --format json
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

# Description: Display detailed system information and resource usage
# Options: --format text|json, --verbose
# Example: worker info system --verbose --format json
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

# Description: Display a high-level overview of the worker image and its capabilities
# Options: --format text|json
# Example: worker info overview --format text
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

# Description: Display available features and their capabilities
# Options: --format text|json
# Example: worker info features --format json
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

    # If no command provided or help requested, show help
    if [ -z "$command" ] || [ "$command" = "help" ]; then
        info_help
        return
    fi

    # Get available commands
    local -A commands
    eval "$(get_command_metadata)"

    # Check if command exists
    if [ -z "${commands[$command]+x}" ]; then
        log_error "Info" "Unknown command: $command"
        info_help
        return 1
    fi

    # Try to execute the command function
    local func_name="show_${command}"
    if declare -F "$func_name" > /dev/null; then
        "$func_name" "$@"
    else
        log_error "Info" "Command handler not implemented: $command"
        return 1
    fi
}
