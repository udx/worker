#!/bin/bash

# Example: Long-running service (autorestart: true)
# Purpose: Shows continuous service pattern
# Status: Shows as RUNNING (✅) while active
# Note: Will be restarted by supervisor if it exits

echo "Starting long-running service..."
while true; do
  echo "Service is running..."
  sleep 5
done
