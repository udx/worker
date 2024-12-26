#!/bin/bash

# Script to run as a systemd service in a loop

while true; do
#   echo "Service is running at $(date)" >> /tmp/service_example.log
  echo "Service is running at $(date)"
  sleep 5
done