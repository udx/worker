#!/bin/bash

# Extract values from .udx file
AZURE_SUBSCRIPTION_ID=$(grep AZURE_SUBSCRIPTION_ID .udx | cut -d '=' -f2)
AZURE_TENANT_ID=$(grep AZURE_TENANT_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_ID=$(grep AZURE_APPLICATION_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_PASSWORD=$(grep AZURE_APPLICATION_PASSWORD .udx | cut -d '=' -f2)

# Generate AZURE_CREDENTIALS in JSON format
AZURE_CREDENTIALS=$(jq -n --arg clientId "$AZURE_APPLICATION_ID" --arg clientSecret "$AZURE_APPLICATION_PASSWORD" --arg subscriptionId "$AZURE_SUBSCRIPTION_ID" --arg tenantId "$AZURE_TENANT_ID" \
'{
  clientId: $clientId,
  clientSecret: $clientSecret,
  subscriptionId: $subscriptionId,
  tenantId: $tenantId,
  activeDirectoryEndpointUrl: "https://login.microsoftonline.com",
  resourceManagerEndpointUrl: "https://management.azure.com/",
  activeDirectoryGraphResourceId: "https://graph.windows.net/",
  sqlManagementEndpointUrl: "https://management.core.windows.net:8443/",
  galleryEndpointUrl: "https://gallery.azure.com/",
  managementEndpointUrl: "https://management.core.windows.net/"
}')

# Escape newlines and export the credentials
echo "AZURE_CREDENTIALS=$(echo $AZURE_CREDENTIALS | jq -c .)" >> $GITHUB_ENV
