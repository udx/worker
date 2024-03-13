#!/bin/bash

# Stop running containers
echo "Stopping running containers..."
docker-compose down
if [ $? -ne 0 ]; then
    echo "Failed to stop containers."
    exit 1
fi

# Remove images
echo "Removing images..."
docker_images=$(docker images -q)
if [ -n "$docker_images" ]; then
    docker rmi $docker_images
    if [ $? -ne 0 ]; then
        echo "Failed to remove images."
        exit 1
    fi
else
    echo "No images to remove."
fi

# Rebuild images
echo "Rebuilding images..."
docker-compose build
if [ $? -ne 0 ]; then
    echo "Failed to build images."
    exit 1
fi

# Start new containers
echo "Starting new containers..."
docker-compose up -d
if [ $? -ne 0 ]; then
    echo "Failed to start containers."
    exit 1
fi

echo "Operation completed successfully."