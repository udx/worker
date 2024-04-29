#!/bin/bash
#
# Cleanup script for the udx-worker.
#
# This script stops all running containers, removes stopped containers, and removes images.
#
# Usage: ./cleanup.sh [-f]
#   -f: Force cleanup without confirmation.
#

set -e

FORCE=0
if [ "$1" == "-f" ]; then
    FORCE=1
fi

# Check if there are any worker containers running
if [ "$(docker-compose ps -q udx-worker)" == "" ]; then
    echo "No worker containers are running."
else
    echo `${docker-compose ps -q udx-worker} | wc -l` "worker containers are running."
fi

# Stop running containers and remove containers, networks, volumes, and images
echo "Stopping running containers and removing containers, networks, volumes, and images confugured in the docker-compose file."
docker-compose down --rmi all --volumes

if [ $FORCE -eq 0 ]; then
    echo "This will remove all stopped containers and images. Are you sure? [y/N]"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Aborting cleanup."
        exit 1
    fi
else
    echo "Force cleanup. Removing all stopped containers and images without confirmation."
fi

echo "Cleanup completed."