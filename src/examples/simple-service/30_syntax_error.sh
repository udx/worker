#!/bin/bash

# Example: Task with error (autorestart: false)
# Purpose: Shows error handling pattern
# Status: Shows as FATAL (💀) on error
# Note: No retry since autorestart is false

echo "Starting task..."
# Intentional syntax error
if then
  echo "This will not run"
fi
if true; then
  echo "This script has a syntax error"
