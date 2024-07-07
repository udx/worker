#!/bin/sh

echo "Starting tests..."

# Print all environment variables for debugging
echo "Printing all environment variables:"
env

# Test environment variables
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "Error: DOCKER_IMAGE_NAME environment variable is not set"
    exit 1
elif [ "$DOCKER_IMAGE_NAME" != "udx-worker" ]; then
    echo "Error: DOCKER_IMAGE_NAME environment variable is not set correctly"
    exit 1
fi

# Test secret resolution (assuming secrets are set as environment variables)
if [ -z "$AZURE_SECRET" ]; then
    echo "Error: Secrets are not resolved correctly"
    exit 1
fi

# Ensure AZURE_APPLICATION_ID and AZURE_TENANT_ID are set
if [ -z "$AZURE_APPLICATION_ID" ]; then
    echo "Error: AZURE_APPLICATION_ID environment variable is not set"
    exit 1
fi

if [ -z "$AZURE_TENANT_ID" ]; then
    echo "Error: AZURE_TENANT_ID environment variable is not set"
    exit 1
fi

# Ensure AZURE_APPLICATION_PASSWORD is not set after cleanup
if [ -n "$AZURE_APPLICATION_PASSWORD" ]; then
    echo "Error: AZURE_APPLICATION_PASSWORD environment variable is still set after cleanup"
    exit 1
fi

# Test Azure CLI
az --version

# Perform cleanup
cleanup_azure

# Test Azure CLI login (this should fail as the AZURE_APPLICATION_PASSWORD is not set)
az login --service-principal -u $AZURE_APPLICATION_ID -p $AZURE_APPLICATION_PASSWORD --tenant $AZURE_TENANT_ID

if [ $? -eq 0 ]; then
    echo "Error: Azure CLI login should have failed since AZURE_APPLICATION_PASSWORD is unset"
    exit 1
fi

echo "All tests passed successfully."
