# Secure Environment Configuration

This directory contains configuration files for setting up a secure UDX Worker environment.

The configurations are designed to ensure that the environment adheres to zero-trust principles and provides maximum security for handling secrets and running automation tasks.

## Files

- `worker.yml`: Main configuration file for environment variables, secrets, and authentication.

## Usage

To use these configuration files, ensure that the `worker.yml` file is correctly configured and placed in the appropriate directory (`/home/$USER/.cd/configs/`) within the container.

### Example Configuration

**worker.yml**

```yaml
config:
  variables:
    DOCKER_IMAGE_NAME: "udx-worker"
  secrets:
    NEW_RELIC_API_KEY: "azure/kv-udx-worker/new-relic-api-key"
    HEALTHCHECK_IO_API_KEY: "azure/kv-udx-worker/healthcheck-io-api-key"
  actors:
    - type: azure
      creds: "${AZURE_CREDS}"
```

## Local Environment Configuration

The `.udx` file is used to store local environment variables required by the UDX Worker. This file should be placed in the root directory of your project.

### Purpose

The `.udx` file contains sensitive environment variables that are referenced in the `worker.yml` configuration file. This allows you to keep secrets out of your configuration files and manage them securely.

### Usage

1. Create a `.udx` file in the root directory of your project.
2. Add the necessary environment variables to the `.udx` file.

### Example

**.udx**

```txt
AZURE_SUBSCRIPTION_ID="b83b62a9-286f-426c-be8a-fc71300f92d2"
AZURE_TENANT_ID="2a8330a4-138c-4c93-977b-cee1faadb2dc"
AZURE_APPLICATION_ID="44f11324-81a9-4573-8853-21c1f44f0ed0"
AZURE_APPLICATION_PASSWORD="*************"
```

### How It's Working

The `.udx` file is loaded by the UDX Worker to populate the environment variables referenced in `worker.yml`. This ensures that sensitive information is managed securely and not hard-coded in configuration files.

### Best Practices

- **Do not hard-code secrets**: Use environment variables or a secrets management tool.
- **Regularly rotate secrets**: Change your secrets periodically to reduce the risk of compromise.
- **Limit access**: Ensure that only authorized personnel have access to the configuration files.
