# UDX Worker Usage Guide

The UDX Worker is a versatile Docker image designed to streamline the automation of tasks while maintaining security and efficiency. This guide provides instructions on configuring and using the UDX Worker in different scenarios.

## Configuration File (worker.yml)

The worker.yml file is essential for setting up environment variables, secrets, and authentication actors.

```yaml
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    DOCKER_IMAGE_NAME: "udx-worker"
    AZURE_SUBSCRIPTION_ID: ${AZURE_SUBSCRIPTION_ID}
    AZURE_TENANT_ID: ${AZURE_TENANT_ID}
    AZURE_APPLICATION_ID: ${AZURE_APPLICATION_ID}
  workerSecrets:
    AZURE_SECRET: "https://kv-udx-worker-secrets.vault.azure.net/secrets/udx-worker-secret-one"
  workerActors:
    - type: azure-service-principal
      subscription: ${AZURE_SUBSCRIPTION_ID}
      tenant: ${AZURE_TENANT_ID}
      application: ${AZURE_APPLICATION_ID}
      password: ${AZURE_APPLICATION_PASSWORD}
```

## Use Cases

### Running Tasks with UDX Worker

1. Prepare Configuration: Ensure your `worker.yml` file is correctly configured and placed in the appropriate directory (`/home/$USER/.cd/configs/`).
