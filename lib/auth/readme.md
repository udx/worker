# Authentication Modules

This directory contains scripts for setting up authentication modules for various cloud providers. These modules allow the UDX Worker to securely authenticate and perform tasks on behalf of the user.

## Prerequisites

- Azure CLI: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- AWS CLI: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- GCP SDK: [Installation Guide](https://cloud.google.com/sdk/docs/install)

## Setup

### Azure Service Principal

#### Create

To create an Azure Service Principal, run the following command:

```shell
az ad sp create-for-rbac --name "udx-worker-sp" --role contributor --scopes /subscriptions/YOUR_SUBSCRIPTION_ID
```

Note the appId, password, and tenant.

#### Use

Update your `worker.yml` configuration file to include the Azure Service Principal credentials:

```yaml
actors:
  - type: azure
    creds: "${AZURE_CREDS}"    
```

### AWS IAM Role (TBD)

Instructions for setting up AWS IAM Role will be provided here.

### GCP Service Account (TBD)

Instructions for setting up GCP Service Account will be provided here.

### Bitwarden Service Account (TBD)

Instructions for setting up GCP Service Account will be provided here.

## Best Practices

- **Use least privilege**: Assign the minimum required permissions to service accounts and roles.
- **Audit access regularly**: Periodically review access logs and permissions to ensure compliance with security policies.
