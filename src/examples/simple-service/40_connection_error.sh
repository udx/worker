#!/bin/bash

# Example: Service with retries (autorestart: true)
# Purpose: Shows retry pattern for recoverable errors
# Status: Shows as RETRY () then FATAL ()
# Note: Supervisor retries 3 times then gives up

echo "Starting service..."
echo "Simulating connection error..."
echo "error: Connection refused to database" >&2
exit 2  # Use exit code 2 for connection errors
