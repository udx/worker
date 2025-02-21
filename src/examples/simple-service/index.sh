#!/bin/bash

# Simple service that prints a message every 5 seconds
echo "Starting simple service..."

# Trap SIGTERM for graceful shutdown
trap 'echo "Received shutdown signal, exiting..."; exit 0' SIGTERM

# Main loop
while true; do
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Simple service is running..."
    sleep 5
done
