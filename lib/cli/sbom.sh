#!/bin/bash

# shellcheck source=${WORKER_LIB_DIR}/utils.sh disable=SC1091
source ${WORKER_LIB_DIR}/utils.sh

# Show help for sbom command
sbom_help() {
    cat << EOF
Manage Software Bill of Materials (SBOM)

Usage: worker sbom [command]

Available Commands:
  generate    Generate SBOM in various formats
  verify      Verify package integrity

Options:
  --format    Output format (text/json)
  --type      Package type (system/python/all)
  --filter    Filter packages by name pattern

Examples:
  worker sbom generate
  worker sbom generate --format json
  worker sbom verify
EOF
}

# Description: Generate Software Bill of Materials in various formats
# Options: --format text|json, --type system|python|all, --filter PATTERN
# Example: worker sbom generate --format json --type python --filter requests
generate_sbom() {
    local format=${1:-text}
    local type=${2:-all}
    local filter=$3
    
    log_info "SBOM" "Generating software bill of materials..." >&2
    
    # Get system packages
    local system_packages
    if [[ $type == "all" || $type == "system" ]]; then
        if [ -n "$filter" ]; then
            system_packages=$(dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\t${Status}\n' | grep "$filter" 2>/dev/null)
        else
            system_packages=$(dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\t${Status}\n' 2>/dev/null)
        fi
    fi
    
    # Get Python packages
    local python_packages
    if [[ $type == "all" || $type == "python" ]]; then
        if [ -n "$filter" ]; then
            python_packages=$(pip list --format=json 2>/dev/null | jq -r '.[] | select(.name | contains("'"$filter"'")) | [.name, .version] | @tsv')
        else
            python_packages=$(pip list --format=json 2>/dev/null | jq -r '.[] | [.name, .version] | @tsv')
        fi
    fi
    
    case $format in
        json)
            {
                # Start JSON object
                echo "{"
                
                # Track if we need a comma between sections
                local need_comma=false
                
                # System packages section
                if [ -n "$system_packages" ]; then
                    echo '  "system_packages": {'
                    # Convert to array for processing
                    mapfile -t packages <<< "$system_packages"
                    local total=${#packages[@]}
                    local count=0
                    
                    for pkg in "${packages[@]}"; do
                        count=$((count + 1))
                        IFS=$'\t' read -r name version arch _ <<< "$pkg"
                        printf '    "%s": {
      "version": "%s",
      "architecture": "%s"
    }' "$name" "$version" "$arch"
                        if [ $count -lt $total ]; then
                            echo ","
                        else
                            echo ""
                        fi
                    done
                    echo "  }"
                    need_comma=true
                fi
                
                # Python packages section
                if [ -n "$python_packages" ]; then
                    if $need_comma; then
                        echo ","
                    fi
                    echo '  "python_packages": {'
                    # Convert to array for processing
                    mapfile -t packages <<< "$python_packages"
                    local total=${#packages[@]}
                    local count=0
                    
                    for pkg in "${packages[@]}"; do
                        count=$((count + 1))
                        IFS=$'\t' read -r name version <<< "$pkg"
                        printf '    "%s": {
      "version": "%s"
    }' "$name" "$version"
                        if [ $count -lt $total ]; then
                            echo ","
                        else
                            echo ""
                        fi
                    done
                    echo "  }"
                fi
                
                # Close JSON object
                echo "}"
            } | jq '.'
            ;;
        text)
            {
                echo "Software Bill of Materials"
                echo "Generated on $(date)"
                echo
                if [ -n "$system_packages" ]; then
                    echo "System Packages:"
                    echo "---------------"
                    echo "Package Name            | Version          | Architecture"
                    echo "----------------------------------------------------------"
                    echo "$system_packages" | awk -F'\t' '{
                        printf("%-20s | %-16s | %-12s\n", $1, $2, $3)
                    }'
                    echo
                fi
                if [ -n "$python_packages" ]; then
                    echo "Python Packages:"
                    echo "---------------"
                    echo "Package Name            | Version"
                    echo "----------------------------------"
                    echo "$python_packages" | awk -F'\t' '{
                        printf("%-20s | %-16s\n", $1, $2)
                    }'
                fi
            }
            ;;
        *)
            log_error "SBOM" "Unknown format: $format" >&2
            return 1
            ;;
    esac
}


# Description: Verify integrity of installed packages
# Options: --type system|python|all
# Example: worker sbom verify --type all
verify_packages() {
    log_info "SBOM" "Verifying package integrity..."
    
    # Verify system packages
    local failed=0
    while IFS= read -r pkg; do
        if ! dpkg -V "$pkg" >/dev/null 2>&1; then
            log_error "SBOM" "Package integrity check failed: $pkg" >&2
            failed=1
        fi
    done < <(dpkg-query -f '${Package}\n' -W)
    
    if [ $failed -eq 0 ]; then
        log_success "SBOM" "All packages verified successfully" >&2
    fi
}

# Parse command line arguments
parse_args() {
    local command=$1
    shift
    
    local format="text"
    local type="all"
    local filter=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                format="$2"
                shift 2
                ;;
            --type)
                type="$2"
                shift 2
                ;;
            --filter)
                filter="$2"
                shift 2
                ;;
            *)
                log_error "SBOM" "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done
    
    echo "$command" "$format" "$type" "$filter"
}

# Handle sbom commands
sbom_handler() {
    if [ $# -eq 0 ]; then
        sbom_help
        return 0
    fi

    local args
    read -r command format type filter <<< "$(parse_args "$@")"
    
    case $command in
        generate)
            if [ "$format" = "json" ]; then
                # Capture all output
                output=$(generate_sbom "$format" "$type" "$filter" 2>&1)
                # Extract only the JSON part (everything between first { and last })
                echo "$output" | awk '/^{/,/^}$/ {print}'
            else
                generate_sbom "$format" "$type" "$filter"
            fi
            ;;
        verify)
            verify_packages
            ;;
        help|"")
            sbom_help
            ;;
        *)
            log_error "SBOM" "Unknown command: $command" >&2
            sbom_help
            return 1
            ;;
    esac
}

# If script is being executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    sbom_handler "$@"
fi
