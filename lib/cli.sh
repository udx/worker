#!/bin/bash

# Dynamically source all command modules
for module in /usr/local/lib/cli/*.sh; do
  # shellcheck disable=SC1090
  source "$module"
done

# shellcheck source=/usr/local/lib/utils.sh disable=SC1091
source /usr/local/lib/utils.sh

# CLI Interface
case $1 in
    env)
        shift
        env_handler "$@"
        ;;
    sbom)
        shift
        sbom_handler "$@"
        ;;
    service)
        shift  
        service_handler "$@"
        ;;
    *)
        log_error "CLI" "Unknown command: $1"
        exit 1
        ;;
esac