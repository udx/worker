# Authentication

This directory contains scripts for setting up authentication modules for various cloud providers. These modules allow the worker container to securely authenticate and perform tasks on behalf of the user.

## Overview

Authentication is a critical component for securely managing interactions with various cloud services. The provided authentication modules support cloud providers like `Azure`, `AWS`, `GCP`, and `Bitwarden`. By utilizing these modules, the worker container can securely access and perform tasks with the necessary permissions.

These authentication modules not only enable the worker container to authenticate with different cloud providers but also allow it to fetch task-specific or application-specific secrets. This ensures that sensitive information is securely retrieved and used only when necessary.

Ensuring proper authentication helps maintain the integrity and security of automated operations in a DevSecOps environment. By adhering to best practices, such as using least privilege and regularly auditing access logs, you can further enhance the security of your workflows.

## Prerequisites

- **Azure CLI**: [Installation Guide](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- **AWS CLI**: [Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **GCP SDK**: [Installation Guide](https://cloud.google.com/sdk/docs/install)
- **Bitwarden CLI**: [Installation Guide](https://bitwarden.com/help/cli/)

## How to Use 

Please check [Secure Environment Configuration](src/configs/readme.md) for config details. 

## Best Practices

- **Use least privilege**: Assign the minimum required permissions to service accounts and roles.
- **Audit access regularly**: Periodically review access logs and permissions to ensure compliance with security policies.