#!/bin/sh

echo "Starting tests..."

# Test environment variables
if [ "$DOCKER_IMAGE_NAME" != "udx-worker" ]; then
    echo "DOCKER_IMAGE_NAME environment variable is not set correctly"
    exit 1
fi

# Test secret resolution (assuming secrets are set as environment variables)
# if [ -z "$AZURE_SECRET" ] || [ -z "$GCP_SECRET" ]; then
#     echo "Secrets are not resolved correctly"
#     exit 1
# fi

echo "All tests passed successfully."
