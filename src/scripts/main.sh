#!/bin/bash

# Script to run as a supervisor service in a loop

end_time=$(($(date +%s) + 30)) # Calculate end_time as current epoch time plus 30 seconds.

while [ "$(date +%s)" -lt $end_time ]; do
    echo "Service is running at $(date)"
    sleep 5
done

echo "30 seconds have elapsed. Exiting now."
exit 0  # Clean exit with status 0, indicating success.