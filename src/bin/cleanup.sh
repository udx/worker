#!/bin/bash

# Stop running containers
echo "Stopping running containers..."
docker-compose down

# Remove images
echo "Removing images..."
docker rmi $(docker images -q)