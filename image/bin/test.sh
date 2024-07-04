#!/bin/sh

echo "Starting tests..."

# Print all environment variables for debugging
echo "Printing all environment variables:"
env

# Test environment variables
if [ -z "$DOCKER_IMAGE_NAME" ]; then
    echo "DOCKER_IMAGE_NAME environment variable is not set"
    exit 1
elif [ "$DOCKER_IMAGE_NAME" != "udx-worker" ]; then
    echo "DOCKER_IMAGE_NAME environment variable is not set correctly"
    exit 1
fi

# Test secret resolution (assuming secrets are set as environment variables)
if [ -z "$AZURE_SECRET" ]; then
    echo "Secrets are not resolved correctly"
    exit 1
fi

# Ensure AZURE_APPLICATION_ID, AZURE_APPLICATION_PASSWORD, and AZURE_TENANT_ID are set
if [ -z "$AZURE_APPLICATION_ID" ]; then
    echo "AZURE_APPLICATION_ID environment variable is not set"
    exit 1
fi

if [ -z "$AZURE_APPLICATION_PASSWORD" ]; then
    echo "AZURE_APPLICATION_PASSWORD environment variable is not set"
    exit 1
fi

if [ -z "$AZURE_TENANT_ID" ]; then
    echo "AZURE_TENANT_ID environment variable is not set"
    exit 1
fi

# Test Azure CLI
az --version

# Test Azure CLI login
az login --service-principal -u $AZURE_APPLICATION_ID -p $AZURE_APPLICATION_PASSWORD --tenant $AZURE_TENANT_ID

if [ $? -ne 0 ]; then
    echo "Azure CLI login failed"
    exit 1
fi

echo "All tests passed successfully."
