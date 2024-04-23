#!/bin/bash
#
# Restart all worker containers.
# This script stops all running containers, removes all images, rebuilds images, and starts new containers.
#
# Usage: ./restart.sh [-f]
#  -f: Force restart without confirmation.
#

set -e

FORCE=0
if [ "$1" == "-f" ]; then
    FORCE=1
fi

if [ $FORCE -eq 0 ]; then
    echo "This will stop all running containers, remove all images, rebuild images, and start new containers. Are you sure? [y/N]"
    read answer
    if [ "$answer" != "y" ]; then
        echo "Aborting restart."
        exit 1
    fi
fi

# Stop running containers
echo "Stopping running containers..."
docker-compose down

# Remove images
docker_images=$(docker images -q)
if [ -n "$docker_images" ]; then
    echo "Removing images..."
    docker rmi $docker_images
else
    echo "No images to remove."
fi

# Rebuild images
echo "Rebuilding images..."
docker-compose build

# Start new containers
echo "Starting new containers..."
docker-compose up -d

echo "Operation completed successfully."