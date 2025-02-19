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
  analyze     Analyze dependencies for security issues
  export      Export SBOM to file
  deps        Show dependency tree
  verify      Verify package integrity
  updates     Check for available updates

Options:
  --format    Output format (text/json/cyclonedx/spdx)
  --file      Output file for export
  --type      Package type (system/python/all)
  --filter    Filter packages by name pattern

Examples:
  worker sbom generate
  worker sbom generate --format json
  worker sbom export --format cyclonedx --file sbom.xml
  worker sbom deps --type python
  worker sbom verify
EOF
}

# Description: Generate Software Bill of Materials in various formats
# Options: --format text|json|cyclonedx|spdx, --type system|python|all, --filter PATTERN
# Example: worker sbom generate --format json --type python --filter requests
generate_sbom() {
    local format=${1:-text}
    local type=${2:-all}
    local filter=$3
    
    log_info "SBOM" "Generating software bill of materials..."
    
    # Get system packages
    local system_packages
    if [[ $type == "all" || $type == "system" ]]; then
        if [ -n "$filter" ]; then
            system_packages=$(dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\t${Status}\n' | grep "$filter")
        else
            system_packages=$(dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\t${Status}\n')
        fi
    fi
    
    # Get Python packages
    local python_packages
    if [[ $type == "all" || $type == "python" ]]; then
        if [ -n "$filter" ]; then
            python_packages=$(pip list --format=json | jq -r '.[] | select(.name | contains("'"$filter"'")) | [.name, .version] | @tsv')
        else
            python_packages=$(pip list --format=json | jq -r '.[] | [.name, .version] | @tsv')
        fi
    fi
    
    case $format in
        json)
            {
                echo "{"
                if [ -n "$system_packages" ]; then
                    echo '  "system_packages": {'
                    echo "$system_packages" | awk -F'\t' '{
                        printf("    \"%s\": {\n      \"version\": \"%s\",\n      \"architecture\": \"%s\"\n    }%s\n", $1, $2, $3, (NR==1?",":""))
                    }'
                    echo "  },"
                fi
                if [ -n "$python_packages" ]; then
                    echo '  "python_packages": {'
                    echo "$python_packages" | awk -F'\t' '{
                        printf("    \"%s\": {\n      \"version\": \"%s\"\n    }%s\n", $1, $2, (NR==1?",":""))
                    }'
                    echo "  }"
                fi
                echo "}"
            } | jq '.'
            ;;
        cyclonedx)
            # Generate CycloneDX XML format
            {
                echo '<?xml version="1.0" encoding="UTF-8"?>'
                echo '<bom xmlns="http://cyclonedx.org/schema/bom/1.4" version="1">'
                echo '  <components>'
                if [ -n "$system_packages" ]; then
                    echo "$system_packages" | awk -F'\t' '{
                        printf("    <component type=\"library\">\n      <name>%s</name>\n      <version>%s</version>\n      <purl>pkg:deb/%s@%s?arch=%s</purl>\n    </component>\n", $1, $2, $1, $2, $3)
                    }'
                fi
                if [ -n "$python_packages" ]; then
                    echo "$python_packages" | awk -F'\t' '{
                        printf("    <component type=\"library\">\n      <name>%s</name>\n      <version>%s</version>\n      <purl>pkg:pypi/%s@%s</purl>\n    </component>\n", $1, $2, $1, $2)
                    }'
                fi
                echo '  </components>'
                echo '</bom>'
            }
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
            log_error "SBOM" "Unknown format: $format"
            return 1
            ;;
    esac
}

# Description: Analyze dependencies for security vulnerabilities
# Options: --type system|python|all, --severity low|medium|high|critical
# Example: worker sbom analyze --type python --severity high
analyze_deps() {
    log_info "SBOM" "Analyzing dependencies for security issues..."
    
    # Check system packages
    if command -v apt-get >/dev/null; then
        apt-get update -qq
        apt-get --simulate upgrade | grep -i security
    fi
    
    # Check Python packages
    if command -v pip-audit >/dev/null; then
        pip-audit
    else
        log_warn "SBOM" "pip-audit not installed. Install with: pip install pip-audit"
    fi
}

# Description: Export SBOM to a file in specified format
# Options: --format text|json|cyclonedx|spdx, --file PATH
# Example: worker sbom export --format cyclonedx --file sbom.xml
export_sbom() {
    local format=$1
    local file=$2
    
    if [ -z "$file" ]; then
        log_error "SBOM" "Output file is required"
        return 1
    fi
    
    generate_sbom "$format" > "$file"
    log_success "SBOM" "SBOM exported to $file"
}

# Description: Display dependency tree for installed packages
# Options: --type system|python|all, --format text|json
# Example: worker sbom deps --type python --format json
show_deps() {
    local type=${1:-all}
    
    if [[ $type == "all" || $type == "python" ]]; then
        log_info "SBOM" "Python dependencies:"
        pip install pipdeptree >/dev/null 2>&1
        pipdeptree
    fi
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
            log_error "SBOM" "Package integrity check failed: $pkg"
            failed=1
        fi
    done < <(dpkg-query -W -f='${binary:Package}\n')
    
    if [ $failed -eq 0 ]; then
        log_success "SBOM" "All packages verified successfully"
    else
        return 1
    fi
}

# Description: Check for available package updates
# Options: --type system|python|all, --format text|json
# Example: worker sbom updates --type all --format json
check_updates() {
    log_info "SBOM" "Checking for available updates..."
    
    # Check system packages
    apt-get update -qq
    apt-get --just-print upgrade 2>&1 | awk '/^Inst/ { print $2 " (" $3 " => " $4 ")" }'
    
    # Check Python packages
    pip list --outdated --format=json | jq -r '.[] | "\(.name) (\(.version) => \(.latest_version))"'
}

# Parse command line arguments
parse_args() {
    local args=()
    while [[ $# -gt 0 ]]; do
        case $1 in
            --format)
                format=$2
                shift 2
                ;;
            --file)
                file=$2
                shift 2
                ;;
            --type)
                type=$2
                shift 2
                ;;
            --filter)
                filter=$2
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

# Handle sbom commands
sbom_handler() {
    local cmd=$1
    shift
    
    # Parse command line arguments
    parse_args "$@"
    
    case $cmd in
        generate)
            generate_sbom "$format" "$type" "$filter"
            ;;
        analyze)
            analyze_deps
            ;;
        export)
            export_sbom "$format" "$file"
            ;;
        deps)
            show_deps "$type"
            ;;
        verify)
            verify_packages
            ;;
        updates)
            check_updates
            ;;
        help)
            sbom_help
            ;;
        *)
            log_error "SBOM" "Unknown command: $cmd"
            sbom_help
            exit 1
            ;;
    esac
}