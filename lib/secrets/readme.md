# Secrets Management

## Overview

Secrets management is a vital component for securely handling sensitive information required by applications and tasks within a containerized environment. The provided secrets management scripts support cloud providers like `Azure`, `AWS`, `GCP`, and `Bitwarden`. These scripts enable the worker container to securely retrieve secrets from different providers and make them available for application logic and task execution.

The scripts ensure that secrets are fetched dynamically at runtime, reducing the risk of exposure and ensuring that applications always have access to the latest sensitive information. By integrating with secure storage solutions and following encryption best practices, these scripts help maintain the confidentiality and integrity of the data used by automated tasks.

### Importance in DevSecOps

In a DevSecOps environment, proper secrets management is crucial for maintaining the security and integrity of automated workflows. By adhering to best practices, such as using least privilege, regularly auditing access, and monitoring for leaks, organizations can significantly reduce the risk of sensitive information exposure.

## Prerequisites

- Azure CLI: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- AWS CLI: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- GCP SDK: [Installation Guide](https://cloud.google.com/sdk/docs/install)

## How to Use 

Please check [Secure Environment Configuration](src/configs/readme.md) for config details. 

## Secrets Configurations

You can find details of secrets configurations for each supported service provider here - [Secrets Configurations](lib/secrets/secrets_configurations.md)

## Best Practices

- **Encrypt secrets**: Ensure secrets are encrypted at rest and in transit.
- **Secure storage**: Use secure storage solutions like AWS Secrets Manager, Azure Key Vault, or Google Secret Manager for storing sensitive information.
- **Monitor for leaks**: Use monitoring tools to detect if secrets are accidentally exposed.