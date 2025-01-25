# Secure Environment Configuration

This directory contains configuration files for setting up a secure worker environment.

The configurations are designed to ensure that the environment adheres to zero-trust principles and provides maximum security for handling secrets and running automation tasks.

## Files

- `worker.yml`: Main configuration file for environment variables, secrets, and authentication.

Your user configuration in `worker.yml` can extend or replace values from the built-in configuration. Below is an example of how you can specify your own environment variables and secrets.

**Example `worker.yml`**

```yaml
---
kind: workerConfig
version: udx.io/worker-v1/config
config:
  env:
    AZURE_CLIENT_ID: "12345678-1234-1234-1234-1234567890ab"
    AZURE_TENANT_ID: "abcdef12-3456-7890-abcd-ef1234567890"
    AZURE_SUBSCRIPTION_ID: "1234abcd-5678-90ef-abcd-12345678abcd"
    AZURE_RESOURCE_GROUP: "rg-example"
    APIM_SERVICE_NAME: "example-apim"
    ACR_REPO_NAME: "exampleacr"
    STORAGE_ACCOUNT_NAME: "examplestorage"
    KEY_VAULT_NAME: "examplekv"
    MANAGED_IDENTITY_NAME: "exampleidentity"

  secrets:
    APP_CLIENT_SECRET: "azure/kv-example/clientSecret"
```

## Usage

To use these configuration files, ensure that the `worker.yml` file is correctly configured and placed in the appropriate directory (`/home/$USER/.cd/configs/`) within the container.

### Volume Mount

If you have a worker configuration outside of the worker image, you can mount it as a volume into the container:

```shell
docker run -d --name udx-worker \
  --env-file .env \
  -v $(pwd)/my-tasks:/usr/src/app \
  -v $(pwd)/.cd/configs/worker.yml:/home/udx/.cd/configs/worker.yml \
  usabilitydynamics/udx-worker:latest
```

### Github Action Integration

In a GitHub Actions workflow, you can mount a configuration file from outside the worker image as a volume into the container:

```yml
name: Deploy with UDX Worker

on:
  workflow_dispatch:

permissions:
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-24.04

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Deploy Using UDX Worker
        env:
          AZURE_CREDS: ${{ secrets.AZURE_CREDS }}
        run: |
          echo "Starting deployment with UDX Worker..."
          docker run --rm \
            -e AZURE_CREDS \
            -v $(pwd)/src/configs/worker.yml:/home/udx/.cd/configs/worker.yml:ro \
            -v $(pwd)/.cd/bin:/home/udx/.cd/bin:ro \
            usabilitydynamics/udx-worker:latest \
            sh -c "
              echo 'Step 1: Show Deployment Variables';
              /home/udx/.cd/bin/10_show_variables.sh;

              echo 'Step 2: Deploy Infrastructure';
              /home/udx/.cd/bin/20_deploy_infra.sh;

              echo 'Step 3: Deploy Application';
              /home/udx/.cd/bin/30_deploy_service.sh;
            "
```

### Child Image Integration

To configure the child worker, you can integrate the configuration into a Docker image.

If you want to include the worker configuration directly in your Docker image, you can use the `COPY` command in your Dockerfile. Assuming your configuration file is located at `src/configs/worker.yml` in your repository, you can add the following line to your Dockerfile:

```
COPY src/worker.yml /home/${USER}/.cd/configs/worker.yml
```

## Configuration Loading and Merging

The [lib/worker_config.sh](../../lib/worker_config.sh) script handles the loading and merging of the configurations. It combines the built-in configuration with user-provided configurations if they exist.

### Process

1. **Built-in Configuration**: The built-in configuration file is located at `/etc/worker/worker.yml`.
2. **User Configuration**: If a user-provided configuration file exists at `/home/$USER/.cd/configs/worker.yml` in the container, it will be merged with the built-in configuration. User configurations can extend or replace values from the built-in configuration.
3. **Merged Configuration**: The merged configuration is stored at `/home/$USER/.cd/configs/merged_worker.yml` and parsed by worker config module logic.
