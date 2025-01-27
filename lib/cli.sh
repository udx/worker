#!/bin/bash

# Dynamically source all command modules
for module in /usr/local/lib/cli/*.sh; do
  source "$module"
done

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
        echo "Usage: $0 {service|env|...}"
        exit 1
        ;;
esac