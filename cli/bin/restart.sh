#!/bin/bash
#
# Restart all worker containers.
# This script stops all running containers, removes all images, rebuilds images, and starts new containers.
#
# Usage: ./restart.sh [-f]
#  -f: Force restart without confirmation.
#

set -e

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "Docker Compose is not installed. Please install Docker Compose and try again."
    exit 1
fi

FORCE=0

# Parse command-line options
while getopts "f" opt; do
    case ${opt} in
        f)
            FORCE=1
        ;;
        \?)
            echo "Invalid option: -$OPTARG" 1>&2
            exit 1
        ;;
    esac
done

if [ $FORCE -eq 0 ]; then
    echo "This will stop all running containers, remove all images, rebuild images, and start new containers. Are you sure? [y/N]"
    read -r answer
    if [ "$answer" != "y" ]; then
        echo "Aborting restart."
        exit 1
    fi
fi

# Stop running containers
echo "Stopping running containers..."
docker-compose down

# Remove stopped containers
echo "Removing stopped containers..."
docker container prune -f

# Remove images
echo "Removing images..."
docker image prune -a -f

# Rebuild images
echo "Rebuilding images..."
docker-compose build

# Start new containers
echo "Starting new containers..."
docker-compose up -d

echo "Operation completed successfully."