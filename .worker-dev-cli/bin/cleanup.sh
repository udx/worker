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
if [ "$(docker ps -q -f name=udx-worker)" == "" ]; then
    echo "No worker containers are running."
    exit 0
else
    echo `${docker ps -q -f name=udx-worker} | wc -l` "worker containers are running."
fi

# Stop running containers
echo "Stopping running containers..."
docker-compose down

if [ $FORCE -eq 0 ]; then
    echo "This will remove all stopped containers and images. Are you sure? [y/N]"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Aborting cleanup."
        exit 1
    fi
fi

# Remove stopped containers
if [ "$(docker ps -a -q)" != "" ]; then
    echo "Removing stopped containers..."
    docker rm $(docker ps -a -q)
fi

# Remove images
if [ "$(docker images -q)" != "" ]; then
    echo "Removing images..."
    docker rmi $(docker images -q)
fi