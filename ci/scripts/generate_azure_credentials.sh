#!/bin/bash

AZURE_SUBSCRIPTION_ID=$(grep AZURE_SUBSCRIPTION_ID .udx | cut -d '=' -f2)
AZURE_TENANT_ID=$(grep AZURE_TENANT_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_ID=$(grep AZURE_APPLICATION_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_PASSWORD=$(grep AZURE_APPLICATION_PASSWORD .udx | cut -d '=' -f2)

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
echo "$AZURE_CREDENTIALS" > azure_credentials.json
echo "AZURE_CREDENTIALS=$(cat azure_credentials.json | jq -sRr @uri)" >> $GITHUB_ENV
