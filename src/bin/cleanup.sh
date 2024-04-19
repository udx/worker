#!/bin/bash

# Stop running containers
echo "Stopping running containers..."
docker-compose down

# Remove stopped containers
echo "Removing stopped containers..."
docker rm $(docker ps -a -q)

# Remove images
echo "Removing images..."
docker rmi $(docker images -q)