#!/bin/sh

echo "Starting tests..."

# Debug: Print the value of DOCKER_IMAGE_NAME
echo "DOCKER_IMAGE_NAME is set to: $DOCKER_IMAGE_NAME"

# Test environment variables
if [ "$DOCKER_IMAGE_NAME" != "udx-worker" ]; then
    echo "DOCKER_IMAGE_NAME environment variable is not set correctly"
    exit 1
fi

# Test secret resolution (assuming secrets are set as environment variables)
if [ -z "$AZURE_SECRET" ]; then
    echo "Secrets are not resolved correctly"
    exit 1
fi

# Test Azure CLI
az --version

# Test Azure CLI login
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_APPLICATION_PASSWORD --tenant $AZURE_TENANT_ID

if [ $? -ne 0 ]; then
    echo "Azure CLI login failed"
    exit 1
fi

echo "All tests passed successfully."
