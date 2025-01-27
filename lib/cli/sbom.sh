#!/bin/bash

# Function to display dpkg packages in a table format using awk
show_sbom() {
    echo "Package Name            | Version          | Architecture"
    echo "----------------------------------------------------------"
    dpkg-query -W -f='${binary:Package} | ${Version} | ${Architecture}\n' | awk -F'|' '{
        printf("%-30s | %-20s | %-10s\n", $1, $2, $3)
    }'
}

# Handler for the sbom command
sbom_handler() {
    case $1 in
        show)
            shift
            show_sbom "$@"
            ;;
        *)
            echo "Usage: $0 sbom show"
            exit 1
            ;;
    esac
}