#!/bin/bash

# Example: Task with error (autorestart: true)
# Purpose: Shows retry pattern for any exit
# Status: Shows as RETRY (🔄) then FATAL (💀)
# Note: Supervisor retries regardless of exit code

echo "Starting task..."
echo "Task failed, will retry..."
exit 1  # Any exit triggers retry with autorestart: true
