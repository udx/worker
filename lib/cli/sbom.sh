#!/bin/bash

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# Function to display dpkg packages in a table format using awk
generate_sbom() {
    log_success "Package Name            | Version          | Architecture"
    log_success "----------------------------------------------------------"
    dpkg-query -W -f='${binary:Package} | ${Version} | ${Architecture}\n' | awk -F'|' '{
        printf("%-30s | %-20s | %-10s\n", $1, $2, $3)
    }'
    log_success "----------------------------------------------------------"
}

# Handler for the sbom command
sbom_handler() {
    case $1 in
        generate)
            shift
            generate_sbom "$@"
            ;;
        *)
            log_warn "CLI" "Usage: $0 sbom {generate}"
            exit 1
            ;;
    esac
}