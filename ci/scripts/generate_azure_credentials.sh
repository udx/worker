#!/bin/bash

# Extract values from .udx file
AZURE_SUBSCRIPTION_ID=$(grep AZURE_SUBSCRIPTION_ID .udx | cut -d '=' -f2)
AZURE_TENANT_ID=$(grep AZURE_TENANT_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_ID=$(grep AZURE_APPLICATION_ID .udx | cut -d '=' -f2)
AZURE_APPLICATION_PASSWORD=$(grep AZURE_APPLICATION_PASSWORD .udx | cut -d '=' -f2)

# Create Azure credentials JSON file
cat <<EOF > azure_credentials.json
{
  "clientId": "$AZURE_APPLICATION_ID",
  "clientSecret": "$AZURE_APPLICATION_PASSWORD",
  "subscriptionId": "$AZURE_SUBSCRIPTION_ID",
  "tenantId": "$AZURE_TENANT_ID",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
EOF
