# Secrets Management Modules

This directory contains scripts for setting up and managing secrets for various cloud providers. These modules enable the UDX Worker to securely fetch and use secrets during its operations.

## Prerequisites

- Azure CLI: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- AWS CLI: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- GCP SDK: [Installation Guide](https://cloud.google.com/sdk/docs/install)

## Setup

### Azure Key Vault

#### Configure

Ensure you have set up an Azure Key Vault and added your secrets. You can add secrets using the Azure CLI:

```shell
az keyvault secret set --vault-name "your-vault-name" --name "your-secret-name" --value "your-secret-value"
```

#### Use

Update your worker.yml configuration file to include the Azure Key Vault secrets:

```yaml
workerSecrets:
  MY_SECRET: "https://your-vault-name.vault.azure.net/secrets/your-secret-name"
```

### AWS IAM Role (TBD)

Instructions for setting up AWS IAM Role will be provided here.

### GCP Service Account (TBD)

Instructions for setting up GCP Service Account will be provided here.

## Best Practices

- **Encrypt secrets**: Ensure secrets are encrypted at rest and in transit.
- **Secure storage**: Use secure storage solutions like AWS Secrets Manager, Azure Key Vault, or Google Secret Manager for storing sensitive information.
- **Monitor for leaks**: Use monitoring tools to detect if secrets are accidentally exposed.
