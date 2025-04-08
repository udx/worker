#!/bin/bash

# Example: One-shot task (autorestart: false)
# Purpose: Shows clean exit pattern using worker service stop
# Status: Shows as STOPPED (⛔) when complete
# Note: Using worker service stop shows task completed successfully

echo "Starting one-shot task..."
echo "Task complete, stopping cleanly..."
worker service stop 20-clean-exit