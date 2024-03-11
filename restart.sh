#!/bin/bash

# Stop running containers
echo "Stopping running containers..."
docker-compose down

# Remove images
echo "Removing images..."
docker rmi $(docker images -q)

# Rebuild images
echo "Rebuilding images..."
docker-compose build

# Start new containers
echo "Starting new containers..."
docker-compose up -d